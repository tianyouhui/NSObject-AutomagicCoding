//
//  AMCExceptionsTest.h
//  AutoMagicCoding
//
//  03.12.11.
//  Copyright 2011 Stepan Generalov.
//
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

#import "AMCExceptionsTest.h"
#import "ObjectsForTests/Bar.h"
#import "ObjectsForTests/Foo.h"

@implementation AMCExceptionsTest

// BadClass have UnsupportedByAMCStruct ivar.
// -dictionaryRepresentation should crash with AMCEncodeException
- (void)testEncodeUnsupportedStructCrash
{    
    BadClass *object = [BadClass new];
    
#ifdef AMC_NO_THROW

    XCTAssertNoThrow(nil == [object dictionaryRepresentation], @"On AMC_NO_THROW AMC should return nil instead of throwing exceptions!");
    
#else
    
    XCTAssertThrowsSpecificNamed([object dictionaryRepresentation] , NSException, AMCEncodeException, @"");

#endif
}

// BadClass have UnsupportedByAMCStruct ivar, that's name is added to 
// AMCKeysForDictionaryRepresentation.
// +objectWithDictionaryRepresentation should crash with AMCDecodeException
- (void)testDecodeUnsupportedStructCrash
{
    // Prepare dictionary representation manually.
    NSDictionary *dict = [NSDictionary dictionaryWithObjects: 
                          [NSArray arrayWithObjects: @"i=5", nil ]
                                                     forKeys: 
                          [NSArray arrayWithObjects: @"struct", nil]
                          ];
    
#ifdef AMC_NO_THROW
    
    XCTAssertNoThrow( nil == [BadClass objectWithDictionaryRepresentation: dict], @"On AMC_NO_THROW AMC should return nil instead of throwing exceptions!");
    
#else
    
    // Crash on decode.
    XCTAssertThrowsSpecificNamed([BadClass objectWithDictionaryRepresentation: dict] , NSException, AMCDecodeException,@"");
    
#endif
}

// Each time when AMC creates dictionary representation of an object - it uses
// -AMCKeysForDictionaryRepresentation return value as an array of keys.
// AMC Uses KVC's -valueForKey: method to retreive values.
// If it's impossible to get value - KVC throws NSUnkownKeyException
- (void) testEncodeWrongKeyInAMCKeysCrash
{
    Foobar *object = [Foobar new]; 
    
#ifdef AMC_NO_THROW
    
    XCTAssertNoThrow( nil == [object dictionaryRepresentation], @"On AMC_NO_THROW AMC should return nil instead of throwing exceptions!");
    
#else
    
    XCTAssertThrowsSpecificNamed([object dictionaryRepresentation], NSException, @"NSUnknownKeyException", @"");
    
#endif
}


// Each time when object is created from dictionary representation - it uses
// className to create an instance, and then uses
// -AMCKeysForDictionaryRepresentation return value as an array of keys.
// If there's no such key in given dict - AMC will skip it &
// no crash will occur.
- (void) testDecodeUnnecessaryKeyInDict
{ 
    // Prepare dictionary representation manually.
    NSDictionary *dict = @{@"wrongKeyThatDoesntExist": @"wrongString"};
    
    // Don't crash on decode.
    XCTAssertNoThrow([Foobar objectWithDictionaryRepresentation: dict], @"");
}

// Changed Foo's dictionaryRepresentation to have Object dictionaryRepresentation 
// in one property instead of simple int value.
// Should crash in KVC's methods with NSInvalidArgumentException
- (void) testDecodeObjectToInt
{
    // ===== Prepare Foo instance. =====
    Foo *foo = [Foo new];
    foo.publicBar = [Bar new];
    foo.integerValue = 17;
    Bar *privateBarInFoo = [Bar new];
    [foo setValue: privateBarInFoo forKey:@"privateBar"];
    foo.publicBar.someString = @"Some Randooooom String! =)";
    privateBarInFoo.someString = @"Some another random string - this time it's in private bar!";
    
    // ===== Save foo's representation in mutable NSDictionary. =====
    NSMutableDictionary *fooDict = [NSMutableDictionary dictionaryWithDictionary: [foo dictionaryRepresentation] ];
    
    // ===== Change integerValue representation with Bar representation in dictionary representation. =====
    NSDictionary *newBarDict = @{@"someString": @"New Bar to set as Int!"};
    [fooDict setObject: newBarDict forKey:@"integerValue"];
    
#ifdef AMC_NO_THROW
    
    XCTAssertNoThrow( nil == [Foo objectWithDictionaryRepresentation: fooDict], @"On AMC_NO_THROW AMC should return nil instead of throwing exceptions!");
    
#else
    
    // Should crash on decoding from corrupted dictionary representation with NSInvalidArgumentException.
    XCTAssertThrowsSpecificNamed([Foo objectWithDictionaryRepresentation: fooDict], NSException, NSInvalidArgumentException, @"");
    
#endif
}

// Changed Foo's dictionaryRepresentation to have simple intValue in
// one property instead of object's (Bar) dictionaryRepresentation.
// Shouldn't crash, but publicBar should be nil.
- (void) testDecodeIntToObject
{
    // ===== Prepare Foo instance. =====
    Foo *foo = [Foo new];
    foo.publicBar = [Bar new];
    foo.integerValue = 17;    
    Bar *privateBarInFoo = [Bar new];
    [foo setValue: privateBarInFoo forKey:@"privateBar"];
    foo.publicBar.someString = @"Some Randooooom String! =)";
    privateBarInFoo.someString = @"Some another random string - this time it's in private bar!";
    
    // ===== Save foo's representation in mutable NSDictionary. =====
    NSMutableDictionary *fooDict = [NSMutableDictionary dictionaryWithDictionary: [foo dictionaryRepresentation] ];
    
    // ===== Change publicBar representation with integerValue representation in foo's dictionary =====
    [fooDict setObject: [NSNumber numberWithInt: 19] forKey:@"publicBar"];
    
    // Shouldn't crash on decode.
    Foo *newFoo = nil;
    XCTAssertNoThrow(newFoo = [Foo objectWithDictionaryRepresentation: fooDict], @"");
    
    // newFoo shouldn't be nil.        
    XCTAssertTrue([newFoo isKindOfClass: [Foo class]], @"foo class should be Foo but it is %@ instead.", [Foo className]);
    
    // publicBar should be nil.
    XCTAssertNil(newFoo.publicBar, @"publicBar can't init from int representation. It should be nil, but it's %@ instead", newFoo.publicBar );
    
    // It shouldn't be NSNumber.
    XCTAssertFalse([newFoo.publicBar isKindOfClass: [NSNumber class]], @"PublicBar is an NSNumber! THIS IS REALLY BAD!!!");
}

- (void) testLoadUnnecessaryKeyInDict
{
    // Prepare dictionary representation manually.
    NSDictionary *dict = @{@"wrongKeyThatDoesntExist": @"wrongString"};
    
    // Create object.
    Foobar *foobar = [[Foobar alloc] init];
    
    // Load unsupported key - don't crash when AMC_NO_THROW defined, crash in KVC-set when not defined.
    
#ifdef AMC_NO_THROW
    
    XCTAssertNoThrow([foobar loadValueForKey:@"wrongKeyThatDoesntExist" fromDictionaryRepresentation: dict], @"On AMC_NO_THROW AMC shouldn't throw exceptions in -loadValueForKey:fromDictionaryRepresentation:!");
#else
    
    // Should crash on decoding from corrupted dictionary representation with NSInvalidArgumentException.
    XCTAssertThrowsSpecificNamed([foobar loadValueForKey:@"wrongKeyThatDoesntExist" fromDictionaryRepresentation: dict], NSException, @"NSUnknownKeyException", @"");
    
#endif
}

- (void) testLoadNotPresentKey
{
    // Prepare dictionary representation without @"wrongKeyThatDoesntExist" key.
    
    // Create object.
    Foobar *foobar = [[Foobar alloc] init];
    
    // Load not present key - nothing happens.
    XCTAssertNoThrow([foobar loadValueForKey:@"wrongKeyThatDoesntExist" fromDictionaryRepresentation: @{}], @"On AMC_NO_THROW AMC shouldn't throw exceptions in -loadValueForKey:fromDictionaryRepresentation:!");
}

@end

@implementation BadClass

// Note: structs can't be just ivars - they must be properties.
// This is needed, because AMC uses property runtime info for getting
// structName;
//@synthesize struct = _struct;

- (NSArray *) AMCKeysForDictionaryRepresentation
{
    return [NSArray arrayWithObjects: @"struct", nil];
}

- (NSString *)classNameWithUnknwonKey:(NSString *)key
{
    if ([key isEqualToString:@"struct"]) {
        return @"UnsupportedByAMCStruct";
    }
    return nil;
}

@end

@implementation Foobar

- (NSArray *) AMCKeysForDictionaryRepresentation
{
    return [NSArray arrayWithObjects: @"noSuchKey", @"anotherWrongKey", nil];
}

@end
