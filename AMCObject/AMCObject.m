//
//  AMCObject.m
//  NSObject+AutoMagicCoding
//  This file is copied from https://github.com/psineur/NSObject-AutomagicCoding
//  and modified by yhtian.

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "AMCObject.h"

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

#import "UIKit/UIKit.h"
#import "CoreGraphics/CoreGraphics.h"

#define NSPoint CGPoint
#define NSSize CGSize
#define NSRect CGRect

#define NSPointFromString CGPointFromString
#define NSSizeFromString CGSizeFromString
#define NSRectFromString CGRectFromString

#define pointValue CGPointValue
#define sizeValue CGSizeValue
#define rectValue CGRectValue

#define NSStringFromPoint NSStringFromCGPoint
#define NSStringFromSize NSStringFromCGSize
#define NSStringFromRect NSStringFromCGRect

#define NSVALUE_ENCODE_POINT(__P__) [NSValue valueWithCGPoint:__P__]
#define NSVALUE_ENCODE_SIZE(__S__) [NSValue valueWithCGSize:__S__]
#define NSVALUE_ENCODE_RECT(__R__) [NSValue valueWithCGRect:__R__]

#else

#define NSVALUE_ENCODE_POINT(__P__) [NSValue valueWithPoint:__P__]
#define NSVALUE_ENCODE_SIZE(__S__) [NSValue valueWithSize:__S__]
#define NSVALUE_ENCODE_RECT(__R__) [NSValue valueWithRect:__R__]

#endif

#import <Availability.h>
#undef AMCRetain
#undef AMCDealloc
#undef AMCAutorelease
#undef AMCDealloc

#if __has_feature(objc_arc)
#define AMCRetain(a) (a)
#define AMCRelease(a) (a)
#define AMCAutorelease(a) (a)
#define AMCDealloc self
#else
#define AMCRetain(a) [a retain]
#define AMCRelease(a) [a release]
#define AMCAutorelease(a) [a autorelease]
#define AMCDealloc dealloc
#endif

NSString *const AMCVersion = @"2.0";
NSString *const AMCEncodeException = @"AMCEncodeException";
NSString *const AMCDecodeException = @"AMCDecodeException";
NSString *const AMCKeyValueCodingFailureException = @"AMCKeyValueCodingFailureException";

#pragma mark - Property Info Helper Functions

/** Returns type of given key.
 * You don't need to call this function directly.
 */
NSArray *AMCPropertyClass(Class class, NSString *key);
NSString *AMCPropertyStruct(Class class, NSString *key);
NSArray *AMCPropertyClassNameWithName(NSString *name);

const char *AMCClassTypeWithKey(Class class, NSString *key);
NSString *AMCPropertyStructName(const char *type);
NSString *AMCPropertyClassName(const char *type);

@implementation AMCObject

+ (BOOL)AMCEnabled
{
    return YES;
}

#pragma mark Decode/Create/Init

+ (id) objectWithDictionaryRepresentation: (NSDictionary *) aDict
{
    if (![aDict isKindOfClass:[NSDictionary class]])
        return nil;

    if ( [self instancesRespondToSelector:@selector(initWithDictionaryRepresentation:) ] )
    {
        id instance = AMCAutorelease([[self alloc] initWithDictionaryRepresentation: aDict]);
        return instance;
    }
    return [[self alloc] init];
}

- (id) initWithDictionaryRepresentation: (NSDictionary *) aDict
{
    // NSObject#init simply returns self, so we don't need to call any init here.
    // See NSObject Class Reference if you don't trust me ;)
    self = [super init];
    @try
    {
        if (aDict)
        {
            NSArray *keysForValues = [self AMCKeysForDictionaryRepresentation];
            for (NSString *propertyName in keysForValues)
            {
                [self loadValueForKey:propertyName fromDictionaryRepresentation:aDict];
            }
        }
        
    }
    
    @catch (NSException *exception) {

#ifdef AMC_NO_THROW
        return nil;
#else
        @throw exception;
#endif
    }
    
    return self;
}

- (void) loadValueForKey:(NSString *)propertyName fromDictionaryRepresentation: (NSDictionary *) aDict
{
    if (aDict && propertyName)
    {
        NSString *key = [self keyWithPropertyName:propertyName];
        id value = [aDict valueForKey: key];
        if ([value isEqual:[NSNull null]] ||
            ([value isKindOfClass:[NSString class]] && [value isEqualToString:@"<null>"])) {
            value = nil;
        }
        if (value)
        {
            AMCFieldType fieldType = [self AMCFieldTypeForValueWithKey: propertyName];
            if (fieldType == kAMCFieldTypeScalar) {
                // is id ?
                fieldType = [self AMCFieldTypeForEncodedObject:value withKey:propertyName];
            }
            if (fieldType == kAMCFieldTypeStructure) {
                value = [self AMCDecodeStructFromString: (NSString *)value
                                               withName: AMCPropertyStruct([self class], propertyName)];
            } else {
                NSArray *array = AMCPropertyClass([self class], propertyName);
                value = [self AMCDecodeObject:value
                                    filedType:fieldType
                              collectionClass:array
                                strippedClass:Nil
                                          key:propertyName];
            }
            [self setValue:value forKey: propertyName];
        }
    }
}

#if !__has_feature(objc_arc)
// recursive to release variables.
- (void)dispose:(id)object {
    NSDictionary *dic = AMCPropertyListOfObject(object);
    for (id key in dic) {
        NSString *value = [dic objectForKey:key];
        const char *attributes = [value UTF8String];
        size_t len = strlen(attributes) + 1;
        char attrs[len];
        strcpy(attrs, attributes);
        char *attr = strtok(attrs, ",");
        BOOL needRelease = NO;
        Ivar ivar = NULL;
        while (attr != NULL) {
            if (attr[0] == 'C' || attr[0] == '&') {
                // Property is 'copy' or 'retain', so we need to release it.
                needRelease = YES;
            } else if (attr[0] == 'V') {
                // Variables started with 'V'.
                ivar = class_getInstanceVariable([object class], attr + 1);
            }
            attr = strtok(NULL, ",");
        }
        if (needRelease && ivar) {
            id obj = object_getIvar(object, ivar);
            if (obj) {
                // If retainCount of |obj| is 1, we need to release it's sub-object.
                if ([obj retainCount] == 1 &&
                    [obj isKindOfClass:[AMCObject class]]) {
                    [self dispose:obj];
                }
                objc_msgSend(obj, @selector(release));
                object_setIvar(object, ivar, nil);
            }
        }
    }
}

#endif

- (void)dealloc {
#if !__has_feature(objc_arc)
    [self dispose:self];
    [super dealloc];
#endif
}

- (id)copyWithZone:(NSZone *)zone
{
    id obj = [[self class] allocWithZone:zone];
    NSDictionary *dic = AMCPropertyListOfObject(self);
    for (id key in dic) {
        [obj setValue:[self valueForKey:key] forKey:key];
    }
    return obj;
}

- (NSString *)debugDescription
{
    NSMutableString *string = [self description].mutableCopy;
    NSMutableString *objStr = [NSMutableString string];
    NSDictionary *dic = AMCPropertyListOfObject(self);
    for (id key in dic) {
        id value = [self valueForKey:key];
        if (value) {
            [objStr appendFormat:@"; %@ = %@", key, value];
        }
    }
    [string insertString:objStr atIndex:[string length] - 1];
    return string;
}

#pragma mark Encode/Save

- (NSDictionary *) dictionaryRepresentation
{
    NSArray *keysForValues = [self AMCKeysForDictionaryRepresentation];
    NSMutableDictionary *aDict = [NSMutableDictionary dictionaryWithCapacity:[keysForValues count] + 1];
    
    @try
    {
        for (NSString *propertyName in keysForValues)
        {
            // Save our current isa, to restore it after using valueForKey:, cause
            // it can corrupt it sometimes (sic!), when getting ccColor3B struct via
            // property/method. (Issue #19)
            Class oldIsa = object_getClass(self);
            
            // Get value with KVC as usual.
            id value = [self valueForKey: propertyName];
            
            if (oldIsa != object_getClass(self))
            {
#ifdef AMC_NO_THROW
                NSLog(@"ATTENTION: isa was corrupted, valueForKey: %@ returned %@ It can be garbage!", propertyName, value);
                
#else
                NSException *exception = [NSException exceptionWithName: AMCKeyValueCodingFailureException
                                                                 reason: [NSString stringWithFormat:@"ATTENTION: isa was corrupted, valueForKey: %@ returned %@ It can be garbage!", propertyName, value]
                                                               userInfo: nil ];
                @throw exception;
#endif
                
                // Restore isa.
                object_setClass(self, oldIsa);
            }
            
            AMCFieldType fieldType = [self AMCFieldTypeForValueWithKey: propertyName encode:YES];
            
            if ( kAMCFieldTypeStructure == fieldType)
            {
                NSString *name = AMCPropertyStruct([self class], propertyName);
                value = [self AMCEncodeStructWithValue: value withName: name];
            }
            else
            {
                value = [self AMCEncodeObject:value filedType:fieldType];
            }
            
            // Scalar or struct - simply use KVC.
            NSString *key = [self keyWithPropertyName:propertyName];
            [aDict setValue:value forKey: key];
        }
    }
    @catch (NSException *exception) {
#ifdef AMC_NO_THROW
        return nil;
#else
        @throw exception;
#endif
    }
    
    return aDict;
}

#pragma mark - override by subclass

- (NSString *)keyWithPropertyName:(NSString *)propertyName
{
    return propertyName;
}

- (NSString *)propertyNameWithKey:(NSString *)key
{
    return key;
}

- (AMCFieldType)unknownFiledTypeWithKey:(NSString *)key
{
    return kAMCFieldTypeScalar;
}

#pragma mark Info for Serialization

- (NSArray *) AMCKeysForDictionaryRepresentation
{
    return AMCKeysForDictionaryRepresentationOfClass([self class]);
}

- (id) AMCDecodeObject: (id) value
             filedType: (AMCFieldType) fieldType
       collectionClass: (NSArray *) collectionClass
         strippedClass: (Class) strippedClass
                   key: (id) key
{
    switch (fieldType)
    {
            // Object as it's representation - create new.
        case kAMCFieldTypeCustomObject:
        {
            if (!collectionClass) {
                return value;
            }
            NSString *class = [collectionClass firstObject];
            Class baseClass = NSClassFromString(class);
            if ([collectionClass count] > 2) { // has more than two protocols, then we know it's really array or dictionary.
                if (classInstancesRespondsToAllSelectorsInProtocol(baseClass, @protocol(AMCArrayProtocol))) {
                    if (classInstancesRespondsToAllSelectorsInProtocol(baseClass, @protocol(AMCArrayMutableProtocol))) {
                        fieldType = kAMCFieldTypeCollectionArrayMutable;
                    } else {
                        fieldType = kAMCFieldTypeCollectionArray;
                    }
                } else if (classInstancesRespondsToAllSelectorsInProtocol([baseClass class], @protocol(AMCHashProtocol))) {
                    if (classInstancesRespondsToAllSelectorsInProtocol(baseClass, @protocol(AMCHashMutableProtocol))) {
                        fieldType = kAMCFieldTypeCollectionHashMutable;
                    } else {
                        fieldType = kAMCFieldTypeCollectionHash;
                    }
                }
                collectionClass = [collectionClass subarrayWithRange:NSMakeRange(1, [collectionClass count] - 1)];
                value = [self AMCDecodeObject: value
                                    filedType: fieldType
                              collectionClass: collectionClass
                                strippedClass: NSClassFromString(class)
                                          key: key];
            } else {
                baseClass = NSClassFromString([collectionClass lastObject]);
                id object = [baseClass objectWithDictionaryRepresentation:(NSDictionary *) value];
                // Here was following code:
                // if (object)
                //    value = object;
                //
                // It was replaced with this one:
                
                value = object;
            }
            
            // To pass -testIntToObjectDecode added in b5522b23a4b484359dca32ddfd38e9dff51bc853
            // In that test dictionaryRepresentation was modified and NSNumber (kAMCFieldTypeScalar)
            // was set to field with type kAMCFieldTypeCustomObject.
            // So there was NSNumber object set instead of Bar in that test.
            // It's possible to modify dictionaryRepresentation so, that one custom object
            // will be set instead of other custom object, but if -objectWithDictionaryRepresentation
            // returns nil - that definetly can't be set as customObject.
            
        }
            break;
            
            
        case kAMCFieldTypeCollectionArray:
        case kAMCFieldTypeCollectionArrayMutable:
        {
            // Create temporary array of all objects in collection.
            id <AMCArrayProtocol> srcCollection = (id <AMCArrayProtocol> ) value;
            NSMutableArray *dstCollection = [NSMutableArray arrayWithCapacity:[srcCollection count]];
            for (unsigned int i = 0; i < [srcCollection count]; ++i)
            {
                id curEncodedObjectInCollection = [srcCollection objectAtIndex: i];
                AMCFieldType type = [self AMCFieldTypeForEncodedObject:curEncodedObjectInCollection
                                                               withKey:key];
                id curDecodedObjectInCollection = [self AMCDecodeObject:curEncodedObjectInCollection
                                                              filedType:type
                                                        collectionClass:collectionClass
                                                          strippedClass:Nil
                                                                    key:key];
                [dstCollection addObject: curDecodedObjectInCollection];
            }
            
            // Get Collection Array Class from property and create object
            Class class = strippedClass;
            if (!class || !classInstancesRespondsToAllSelectorsInProtocol(strippedClass, @protocol(AMCArrayProtocol))) {
                if (fieldType == kAMCFieldTypeCollectionArray)
                    class = [NSArray class];
                else
                    class = [NSMutableArray class];
            }
            id <AMCArrayProtocol> object = (id <AMCArrayProtocol> )[class alloc];
            @try
            {
                object = [object initWithArray: dstCollection];
            }
            @finally {
                AMCAutorelease(object);
            }
            
            if (object)
                value = object;
        }
            break;
            
        case kAMCFieldTypeCollectionHash:
        case kAMCFieldTypeCollectionHashMutable:
        {
            // Create temporary array of all objects in collection.
            NSObject <AMCHashProtocol> *srcCollection = (NSObject <AMCHashProtocol> *) value;
            NSMutableDictionary *dstCollection = [NSMutableDictionary dictionaryWithCapacity:[srcCollection count]];
            for (NSString *curKey in [srcCollection allKeys])
            {
                id curEncodedObjectInCollection = [srcCollection valueForKey: curKey];
                // A hack, while some dictionary has different type of current object class,
                // we use it.
                AMCFieldType type = [self unknownFiledTypeWithKey:curKey];
                if (type == kAMCFieldTypeScalar) {
                    type = [self AMCFieldTypeForEncodedObject:curEncodedObjectInCollection
                                                      withKey:key];
                }
                id curDecodedObjectInCollection = [self AMCDecodeObject:curEncodedObjectInCollection
                                                              filedType:type
                                                        collectionClass:collectionClass
                                                          strippedClass:Nil
                                                                    key:key];
                NSString *propertyName = [self propertyNameWithKey:curKey];
                [dstCollection setObject: curDecodedObjectInCollection forKey: propertyName];
            }
            
            // Get Collection Array Class from property and create object
            Class class = strippedClass;
            if (!class || !classInstancesRespondsToAllSelectorsInProtocol(strippedClass, @protocol(AMCHashProtocol))) {
                if (fieldType == kAMCFieldTypeCollectionHash)
                    class = [NSDictionary class];
                else
                    class = [NSMutableDictionary class];
            }
            
            id <AMCHashProtocol> object = (id <AMCHashProtocol> )[class alloc];
            @try
            {
                object = [object initWithDictionary: dstCollection];
            }
            @finally {
                AMCAutorelease(object);
            }
            
            if (object)
                value = object;
        }            break;
            
            // Scalar or struct - simply use KVC.
        case kAMCFieldTypeScalar:
            // Add a NSDate type create.
            if ([NSClassFromString([collectionClass firstObject]) isSubclassOfClass:[NSDate class]] &&
                [value isKindOfClass:[NSNumber class]]) {
                value = [NSDate dateWithTimeIntervalSince1970:[value longLongValue]];
            }
            break;
        default:
            break;
    }
    
    return value;
}

- (id) AMCEncodeObject: (id) value filedType: (AMCFieldType) fieldType
{
    switch (fieldType)
    {
            // Object as it's representation - create new.
        case kAMCFieldTypeCustomObject:
        {
            if ([value respondsToSelector:@selector(dictionaryRepresentation)])
                value = [value dictionaryRepresentation];
        }
            break;
            
        case kAMCFieldTypeCollectionArray:
        case kAMCFieldTypeCollectionArrayMutable:
        {
            
            id <AMCArrayProtocol> collection = (id <AMCArrayProtocol> )value;
            NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity: [collection count]];
            
            for (unsigned int i = 0; i < [collection count]; ++i)
            {
                NSObject *curObjectInCollection = [collection objectAtIndex: i];
                AMCFieldType type = [self AMCFieldTypeForObjectToEncode:curObjectInCollection
                                                                withKey:nil];
                NSObject *curObjectInCollectionEncoded = [self AMCEncodeObject:curObjectInCollection
                                                                     filedType:type];
                [tmpArray addObject: curObjectInCollectionEncoded];
            }
            
            value = tmpArray;
        }
            break;
            
        case kAMCFieldTypeCollectionHash:
        case kAMCFieldTypeCollectionHashMutable:
        {
            NSObject <AMCHashProtocol> *collection = (NSObject <AMCHashProtocol> *)value;
            NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithCapacity: [collection count]];
            
            for (NSString *curKey in [collection allKeys])
            {
                NSObject *curObjectInCollection = [collection valueForKey: curKey];
                NSString *key = [self keyWithPropertyName:curKey];
                AMCFieldType type = [self AMCFieldTypeForObjectToEncode:curObjectInCollection
                                                                withKey:curKey];
                NSObject *curObjectInCollectionEncoded = [self AMCEncodeObject:curObjectInCollection
                                                                     filedType:type];
                [tmpDict setObject:curObjectInCollectionEncoded forKey:key];
            }
            
            value = tmpDict;
        }
            break;
            
            
            // Scalar or struct - simply use KVC.
        case kAMCFieldTypeScalar:
            break;
        default:
            break;
    }
    
    return value;
}

- (AMCFieldType) AMCFieldTypeForValueWithKey: (NSString *) aKey
{
    return [self AMCFieldTypeForValueWithKey: aKey encode: NO];
}

- (AMCFieldType) AMCFieldTypeForValueWithKey: (NSString *) aKey encode:(BOOL) encode
{
    // isAutoMagicCodingEnabled == YES? Then it's custom object.
    NSString *determinClass;
    NSArray *array = AMCPropertyClass([self class], aKey);
    if (encode || [array count] <= 2) {
        determinClass = [array firstObject];
        if (NSClassFromString(determinClass) == Nil) {
            determinClass = [array lastObject];
        }
    } else {
        determinClass = [array lastObject];
    }
    Class class = NSClassFromString(determinClass);
    
    if ([class isSubclassOfClass:[AMCObject class]] && [class AMCEnabled])
        return kAMCFieldTypeCustomObject;

    // Is it ordered collection?
    if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCArrayProtocol) ) )
    {
        // Mutable?
        if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCArrayMutableProtocol) ) )
            return kAMCFieldTypeCollectionArrayMutable;
        
        // Not Mutable.
        return kAMCFieldTypeCollectionArray;
    }
    
    // Is it hash collection?
    if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCHashProtocol) ) )
    {
        // Mutable?
        if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCHashMutableProtocol) ) )
            return kAMCFieldTypeCollectionHashMutable;
        
        // Not Mutable.
        return kAMCFieldTypeCollectionHash;
    }
    
    // Is it a structure?
    NSString *structName = AMCPropertyStruct([self class], aKey);
    if (structName)
        return kAMCFieldTypeStructure;
    
    // Otherwise - it's a scalar or PLIST-Compatible object (i.e. NSString)
    return kAMCFieldTypeScalar;
}

- (AMCFieldType)AMCFieldTypeForEncodedObject:(id)object withKey:(NSString *)aKey
{
    id class = [object class];
    
    // Is it ordered collection?
    if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCArrayProtocol) ) )
    {
        // Mutable?
        if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCArrayMutableProtocol) ) )
            return kAMCFieldTypeCollectionArrayMutable;
        
        // Not Mutable.
        return kAMCFieldTypeCollectionArray;
    }
    
    // Is it hash collection?
    if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCHashProtocol) ) )
    {
        // Maybe it's custom object encoded in NSDictionary?
        if (aKey && [object respondsToSelector:@selector(objectForKey:)])
        {
            NSArray *array = AMCPropertyClass([self class], aKey);
            Class encodedObjectClass = NSClassFromString([array lastObject]); // After all, the last class should be AMCObject.
            if ([encodedObjectClass isSubclassOfClass:[AMCObject class]] &&
                [encodedObjectClass AMCEnabled]) {
                return kAMCFieldTypeCustomObject;
            }
        }
        
        // Mutable?
        if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCHashMutableProtocol) ) )
            return kAMCFieldTypeCollectionHashMutable;
        
        // Not Mutable.
        return kAMCFieldTypeCollectionHash;
    }
    
    
    return kAMCFieldTypeScalar;
}

- (AMCFieldType) AMCFieldTypeForObjectToEncode:(id) object withKey:(NSString *)key
{
    id class = [object class];
    
    // Is it custom object with dictionaryRepresentation support?
    if ([class isSubclassOfClass:[AMCObject class]] && [class AMCEnabled] &&
        ([object respondsToSelector:@selector(dictionaryRepresentation)]))
    {
        return kAMCFieldTypeCustomObject;
    }
    
    // Is it ordered collection?
    if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCArrayProtocol) ) )
    {
        // Mutable?
        if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCArrayMutableProtocol) ) )
            return kAMCFieldTypeCollectionArrayMutable;
        
        // Not Mutable.
        return kAMCFieldTypeCollectionArray;
    }
    
    // Is it hash collection?
    if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCHashProtocol) ) )
    {
        // Mutable?
        if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCHashMutableProtocol) ) )
            return kAMCFieldTypeCollectionHashMutable;
        
        // Not Mutable.
        return kAMCFieldTypeCollectionHash;
    }
    
    return kAMCFieldTypeScalar;
}

- (NSString *) AMCClassNameWithKey: (NSString *) aKey
{
    const char *type = AMCClassTypeWithKey([self class], aKey);
    NSString *className = AMCPropertyClassName (type);
    return className;
}


#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

- (NSString *) className
{
    const char* name = class_getName([self class]);
    
    return [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
}

+ (NSString *) className
{
    const char* name = class_getName([self class]);
    
    return [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
}

#endif

#pragma mark Structure Support

- (NSValue *) AMCDecodeStructFromString: (NSString *)value withName: (NSString *) structName
{
    // valueForKey: never returns CGPoint, CGRect, etc - it returns NSPoint, NSRect stored in NSValue instead.
    // This is why here was made no difference between struct names such CGP
    
    if ([structName isEqualToString:@"CGPoint"] || [structName isEqualToString:@"NSPoint"])
    {
        NSPoint p = NSPointFromString(value);
        
        return NSVALUE_ENCODE_POINT(p);
    }
    else if ([structName isEqualToString:@"CGSize"] || [structName isEqualToString:@"NSSize"])
    {
        NSSize s = NSSizeFromString(value);
        
        return NSVALUE_ENCODE_SIZE(s);
    }
    else if ([structName isEqualToString:@"CGRect"] || [structName isEqualToString:@"NSRect"])
    {
        NSRect r = NSRectFromString(value);
        
        return NSVALUE_ENCODE_RECT(r);
    }
    
    if (!structName)
        structName = @"(null)";
    NSException *exception = [NSException exceptionWithName: AMCDecodeException
                                                     reason: [NSString stringWithFormat:@"AMCDecodeException: %@ is unsupported struct.", structName]
                                                   userInfo: nil ];
    
    @throw exception;
    
    return nil;
}

- (NSString *) AMCEncodeStructWithValue: (NSValue *) structValue withName: (NSString *) structName
{
    // valueForKey: never returns CGPoint, CGRect, etc - it returns NSPoint, NSRect stored in NSValue instead.
    // This is why here was made no difference between struct names such CGPoint & NSPoint.
    
    if ( [structName isEqualToString:@"CGPoint"] || [structName isEqualToString:@"NSPoint"])
    {
        NSPoint point = [structValue pointValue];
        
        return NSStringFromPoint(point);
    }
    else if ( [structName isEqualToString:@"CGSize"] || [structName isEqualToString:@"NSSize"])
    {
        NSSize size = [structValue sizeValue];
        
        return NSStringFromSize(size);
    }
    else if ( [structName isEqualToString:@"CGRect"] || [structName isEqualToString:@"NSRect"])
    {
        NSRect rect = [structValue rectValue];
        
        return NSStringFromRect(rect);
    }
    
    if (!structName)
        structName = @"(null)";
    NSException *exception = [NSException exceptionWithName: AMCEncodeException
                                                     reason: [NSString stringWithFormat:@"AMCEncodeException: %@ is unsupported struct.", structName]
                                                   userInfo: nil ];
    
    @throw exception;
    
    return nil;
}

#pragma mark Helper Functions

const char *AMCClassTypeWithKey(Class class, NSString *key)
{
    objc_property_t property = class_getProperty(class, [key cStringUsingEncoding:NSUTF8StringEncoding]);
    if (property) {
        const char *attributes = property_getAttributes(property);
        return attributes;
    } else {
        // private ?
        Ivar var = class_getInstanceVariable(class, [key cStringUsingEncoding:NSUTF8StringEncoding]);
        if (var == NULL) {
            var = class_getInstanceVariable(class, [[@"_" stringByAppendingString:key] cStringUsingEncoding:NSUTF8StringEncoding]);
            if (var == NULL) {
                var = class_getInstanceVariable(class, [[key stringByAppendingString:@"_"] cStringUsingEncoding:NSUTF8StringEncoding]);
            }
        }
        if (var) {
            const char *type = ivar_getTypeEncoding(var);
            return type;
        }
    }
    return nil;
}

NSString *AMCPropertyClassName (const char *type)
{
    if (!type)
        return nil;
    
    char *classNameCString = strstr(type, "@\"");
    if ( classNameCString )
    {
        classNameCString += 2; //< skip @" substring
        NSString *classNameString = [NSString stringWithCString:classNameCString encoding:NSUTF8StringEncoding];
        NSRange range = [classNameString rangeOfString:@"\""];
        
        classNameString = [classNameString substringToIndex: range.location];
        return classNameString;
    }
    return nil;
}

NSString *AMCPropertyStructName(const char *type)
{
    if (!type)
        return nil;

    char *structNameCString = strstr(type, "T{");
    if ( structNameCString )
    {
        structNameCString += 2; //< skip T{ substring
        NSString *structNameString = [NSString stringWithCString:structNameCString encoding:NSUTF8StringEncoding];
        NSRange range = [structNameString rangeOfString:@"="];
        
        structNameString = [structNameString substringToIndex: range.location];
        
        return structNameString;
    } else {
        structNameCString = strstr(type, "{");
        if (structNameCString) {
            structNameCString += 1; //< skip { substring
            NSString *structNameString = [NSString stringWithCString:structNameCString encoding:NSUTF8StringEncoding];
            NSRange range = [structNameString rangeOfString:@"="];
            
            structNameString = [structNameString substringToIndex: range.location];
            
            return structNameString;
        }
    }
    return nil;
}

NSArray *AMCPropertyClassNameWithName(NSString *name)
{
    if (!name) {
        return nil;
    }
    NSString *string = [name stringByReplacingOccurrencesOfString:@">" withString:@""];
    NSArray *array = [string componentsSeparatedByString:@"<"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF != %@", @""];
    return [array filteredArrayUsingPredicate:predicate];
}

NSArray *AMCPropertyClass (Class class, NSString *key)
{
    const char *type = AMCClassTypeWithKey(class, key);
    NSString *string = AMCPropertyClassName(type);
    return AMCPropertyClassNameWithName(string);
}

NSString *AMCPropertyStruct (Class class, NSString *key)
{
    const char *type = AMCClassTypeWithKey(class, key);
    NSString *string = AMCPropertyStructName(type);
    return string;
}

static NSDictionary *AMCPropertyListOfObject(id object)
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    unsigned int numProps = 0;
    objc_property_t *properties = class_copyPropertyList([object class], &numProps);
    for (int i = 0; i < numProps; i++) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        NSString *key = [NSString stringWithUTF8String:name];
        // iOS8 add these...
        if ([NSObject instancesRespondToSelector:NSSelectorFromString(key)]) {
            continue;
        }
        const char *attribute = property_getAttributes(property);
        NSString *value = [NSString stringWithUTF8String:attribute];
        [dic setObject:value forKey:key];
    }
    free(properties);
    return dic;
}

BOOL classInstancesRespondsToAllSelectorsInProtocol(id class, Protocol *p )
{
    unsigned int outCount = 0;
    struct objc_method_description *methods = NULL;
    if (!class || !p) {
        return NO;
    }
    methods = protocol_copyMethodDescriptionList( p, YES, YES, &outCount);
    
    for (unsigned int i = 0; i < outCount; ++i)
    {
        SEL selector = methods[i].name;
        if (![class instancesRespondToSelector: selector])
        {
            if (methods)
                free(methods);
            methods = NULL;
            
            return NO;
        }
    }
    
    if (methods)
        free(methods);
    methods = NULL;
    
    return YES;
}

NSArray *AMCKeysForDictionaryRepresentationOfClass(Class cls)
{
    // Array that will hold properties names.
    NSMutableArray *array = [NSMutableArray array/*WithCapacity: 0*/];
    
    // Go through superClasses from self class to NSObject to get all inherited properties.
    id curClass = cls;
    while (1)
    {
        // Stop on NSObject.
        if (curClass && curClass == [NSObject class])
            break;
        
        // Use objc runtime to get all properties and return their names.
        unsigned int outCount;
        objc_property_t *properties = class_copyPropertyList(curClass, &outCount);
        
        // Reverse order of curClass properties, cause we will return reversed array.
        for (int i = outCount - 1; i >= 0; --i)
        {
            objc_property_t curProperty = properties[i];
            const char *name = property_getName(curProperty);
            
            NSString *propertyKey = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
            // iOS8 add these...
            if ([NSObject instancesRespondToSelector:NSSelectorFromString(propertyKey)]) {
                continue;
            }
            [array addObject: propertyKey];
        }
        
        if (properties)
            free(properties);
        
        // Next.
        curClass = [curClass superclass];
    }
    
    id result = [[array reverseObjectEnumerator] allObjects];
    
    return result;
}

@end

@implementation NSObject (AMCRepresentation)

+ (id) objectWithRepresentation: (id)representation
{
    return [self objectWithRepresentation:representation className:nil];
}

+ (id) objectWithRepresentation: (id)representation className: (NSString *)className
{
    id container = nil;
    Class cls;
    if (className == nil || [NSClassFromString(className) isSubclassOfClass:[AMCObject class]]) {
        if (className != nil) {
            cls = NSClassFromString(className);
        } else if ([self isSubclassOfClass:[AMCObject class]]) {
            cls = self;
        }
        if ([representation isKindOfClass:[NSDictionary class]]) {
            container = [cls objectWithDictionaryRepresentation:representation];
        } else if ([representation isKindOfClass:[NSArray class]]) {
            container = [[NSMutableArray alloc] init];
            for (NSDictionary *dic in representation) {
                id obj = [cls objectWithDictionaryRepresentation:dic];
                if (obj) {
                    [container addObject:obj];
                }
            }
            return container;
        } else {
            container = [[[self class] alloc] init];
        }
    } else {
        NSArray *classes = AMCPropertyClassNameWithName(className);
        cls = NSClassFromString([classes firstObject]);
        NSAssert([representation isKindOfClass:cls],
                 @"Mailformed class %@ for %@", cls, representation);
        classes = [classes subarrayWithRange:NSMakeRange(1, [classes count] - 1)];
        className = [classes componentsJoinedByString:@"<"];
        if ([cls isSubclassOfClass:[NSDictionary class]]) {
            container = [[NSMutableDictionary alloc] init];
            for (id key in representation) {
                id obj = [self objectWithRepresentation:[representation objectForKey:key]
                                              className:className];
                [container setObject:obj forKey:key];
            }
        } else if ([cls isSubclassOfClass:[NSArray class]]) {
            container = [[NSMutableArray alloc] init];
            for (id object in representation) {
                id obj = [self objectWithRepresentation:object
                                              className:className];
                [container addObject:obj];
            }
        } else {
            container = [[[self class] alloc] init];
        }
    }
    return container;
}

- (id) representation
{
    id representation = self;
    id container;
    if ([self isKindOfClass:[NSArray class]]) {
        container = [[NSMutableArray alloc] init];
        for (id obj in representation) {
            if ([obj isKindOfClass:[AMCObject class]]) {
                id object = [obj dictionaryRepresentation];
                if (object) {
                    [container addObject:object];
                }
            } else if ([obj isKindOfClass:[NSArray class]] ||
                       [obj isKindOfClass:[NSDictionary class]]) {
                id object = [obj representation];
                if (object) {
                    [container addObject:object];
                }
            } else {
                [container addObject:obj];
            }
        }
        return container;
    } else if ([self isKindOfClass:[NSDictionary class]]) {
        container = [[NSMutableDictionary alloc] init];
        for (id key in representation) {
            id obj = [representation objectForKey:key];
            if ([obj isKindOfClass:[AMCObject class]]) {
                id object = [obj dictionaryRepresentation];
                if (object) {
                    [container setObject:object forKey:key];
                }
            } else if ([obj isKindOfClass:[NSArray class]] ||
                       [obj isKindOfClass:[NSDictionary class]]) {
                id object = [obj representation];
                if (object) {
                    [container setObject:object forKey:key];
                }
            } else {
                [container setObject:obj forKey:key];
            }
        }
        return container;
    } else if ([self isKindOfClass:[AMCObject class]]) {
        return [representation dictionaryRepresentation];
    }
    return self;
}

@end
