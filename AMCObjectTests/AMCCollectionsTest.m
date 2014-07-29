//
//  AMCCollectionsTest.m
//  AutoMagicCoding
//
//   02.09.11.
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

#import "AMCCollectionsTest.h"
#import "AMCObject.h"

// Test objects.
#import "ObjectsForTests/Foo.h"
#import "ObjectsForTests/FooWithCollections.h"
#import "ObjectsForTests/FooWithMutableCollections.h"
#import "ObjectsForTests/Bar.h"
#import "ObjectsForTests/FooWithCustomCollection.h"

@implementation AMCCollectionsTest
@synthesize fooWithCollections = _fooWithCollections;

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    self.fooWithCollections = [FooWithCollections new];
}

- (void) testEmptyCollectionsInMemory
{
    // Prepare source foo.
    self.fooWithCollections.array = (NSArray<Foo> *)@[];
    self.fooWithCollections.dict = (NSDictionary<Bar> *)@{};
    
    // Save & Load.
    NSDictionary *fooDict = [self.fooWithCollections dictionaryRepresentation];   
    // Create new object from that dictionary.
    FooWithCollections *newFoo = [FooWithCollections objectWithDictionaryRepresentation: fooDict];
    
    // Test newFoo.
    XCTAssertNotNil(newFoo, @"newFoo failed to create.");
    
    if (![[newFoo className] isEqualToString: [FooWithCollections className]])
        XCTFail(@"newFoo should be FooWithCollections!");
    XCTAssertTrue( [newFoo isMemberOfClass: [FooWithCollections class]], @"newFoo is NOT MemberOfClass FooWithCollections!" );
    
    // Test newFoo collections.
    XCTAssertNotNil(newFoo.array, @"newFoo.array failed to create.");
    XCTAssertNotNil(newFoo.dict, @"newFoo.dict failed to create.");    
    XCTAssertTrue( [newFoo.array isKindOfClass: [NSArray class]], @"newFoo.array is NOT KindOfClass NSArray!" );    
    XCTAssertTrue( [newFoo.dict isKindOfClass: [NSDictionary class]], @"newFoo.dict is NOT KindOfClass NSDictionary!" );
    
    // Test newFoo collections to be empty.
    XCTAssertTrue([newFoo.array count] == 0, @"newFoo.array is not empty!" );
    XCTAssertTrue([newFoo.dict count] == 0, @"newFoo.dict is not empty!" );
}

- (void) testEmptyCollectionsInFile
{
    // Prepare source foo.
    self.fooWithCollections.array = (NSArray<Foo> *)@[];
    self.fooWithCollections.dict = (NSDictionary<Bar> *)@{};
    
    // Save object representation in PLIXCT & Create new object from that PLIXCT.
    NSString *path = [self testFilePathWithSuffix:@"Empty"];
    NSDictionary *dictRepr =[self.fooWithCollections dictionaryRepresentation];
    [dictRepr writeToFile: path atomically:YES]; 
    FooWithCollections *newFoo = [FooWithCollections objectWithDictionaryRepresentation: [NSDictionary dictionaryWithContentsOfFile: path]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: path ])
        XCTFail(@"Test file with path = %@ not exist! Dictionary representation = %@", path, dictRepr);
    
    // Test newFoo.
    XCTAssertNotNil(newFoo, @"newFoo failed to create.");
    
    if (![[newFoo className] isEqualToString: [FooWithCollections className]])
        XCTFail(@"newFoo should be FooWithCollections!");
    XCTAssertTrue( [newFoo isMemberOfClass: [FooWithCollections class]], @"newFoo is NOT MemberOfClass FooWithCollections!" );
    
    // Test newFoo collections.
    XCTAssertNotNil(newFoo.array, @"newFoo.array failed to create.");
    XCTAssertNotNil(newFoo.dict, @"newFoo.dict failed to create.");    
    XCTAssertTrue( [newFoo.array isKindOfClass: [NSArray class]], @"newFoo.array is NOT KindOfClass NSArray!" );    
    XCTAssertTrue( [newFoo.dict isKindOfClass: [NSDictionary class]], @"newFoo.dict is NOT KindOfClass NSDictionary!" );
    
    // Test newFoo collections to be empty.
    XCTAssertTrue([newFoo.array count] == 0, @"newFoo.array is not empty!" );
    XCTAssertTrue([newFoo.dict count] == 0, @"newFoo.dict is not empty!" );
}

- (void) testStringCollectionsInMemory
{
    // Prepare source foo.
    self.fooWithCollections.array = (NSArray<Foo> *)@[@"one", @"three", @"two", @"ah!"];
    self.fooWithCollections.dict = (NSDictionary<Bar> *)@{@"key1": @"obj1", @"key2": @"obj2", @"key3": @"obj3"};

    // Save & Load.
    NSDictionary *fooDict = [self.fooWithCollections dictionaryRepresentation];   
    // Create new object from that dictionary.
    FooWithCollections *newFoo = [FooWithCollections objectWithDictionaryRepresentation: fooDict];
    
    // Test newFoo.
    XCTAssertNotNil(newFoo, @"newFoo failed to create.");
    
    if (![[newFoo className] isEqualToString: [FooWithCollections className]])
        XCTFail(@"newFoo should be FooWithCollections!");
    XCTAssertTrue( [newFoo isMemberOfClass: [FooWithCollections class]], @"newFoo is NOT MemberOfClass FooWithCollections!" );
    
    // Test newFoo collections.
    XCTAssertNotNil(newFoo.array, @"newFoo.array failed to create.");
    XCTAssertNotNil(newFoo.dict, @"newFoo.dict failed to create.");    
    XCTAssertTrue( [newFoo.array isKindOfClass: [NSArray class]], @"newFoo.array is NOT KindOfClass NSArray!" );    
    XCTAssertTrue( [newFoo.dict isKindOfClass: [NSDictionary class]], @"newFoo.dict is NOT KindOfClass NSDictionary!" );
    
    // Test newFoo collections to be the same size.
    XCTAssertTrue([newFoo.array count] == [self.fooWithCollections.array count], @"newFoo.array count is not wrong!" );
    XCTAssertTrue([newFoo.dict count] == [self.fooWithCollections.dict count], @"newFoo.dict count is not wrong!" );
    
    XCTAssertTrue([ self array:newFoo.array isEqualTo: self.fooWithCollections.array], @"newFoo.array is not equal with the original!" );
    XCTAssertTrue([ self dict: newFoo.dict isEqualTo: self.fooWithCollections.dict], @"newFoo.dict is not equal with the original!" );
}

- (void) testStringCollectionsInFile
{
    // Prepare source foo.
    self.fooWithCollections.array = (NSArray<Foo> *)@[@"one", @"three", @"two", @"ah!"];
    self.fooWithCollections.dict = (NSDictionary<Bar> *)@{@"key1": @"obj1", @"key2": @"obj2", @"key3": @"obj3"};
    
    // Save object representation in PLIXCT & Create new object from that PLIXCT.
    NSString *path = [self testFilePathWithSuffix:@"String"];
    NSDictionary *dictRepr =[self.fooWithCollections dictionaryRepresentation];
    [dictRepr writeToFile: path atomically:YES]; 
    FooWithCollections *newFoo = [FooWithCollections objectWithDictionaryRepresentation: [NSDictionary dictionaryWithContentsOfFile: path]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: path ])
        XCTFail(@"Test file with path = %@ not exist! Dictionary representation = %@", path, dictRepr);
    
    // Test newFoo.
    XCTAssertNotNil(newFoo, @"newFoo failed to create.");
    
    if (![[newFoo className] isEqualToString: [FooWithCollections className]])
        XCTFail(@"newFoo should be FooWithCollections!");
    XCTAssertTrue( [newFoo isMemberOfClass: [FooWithCollections class]], @"newFoo is NOT MemberOfClass FooWithCollections!" );
    
    // Test newFoo collections.
    XCTAssertNotNil(newFoo.array, @"newFoo.array failed to create.");
    XCTAssertNotNil(newFoo.dict, @"newFoo.dict failed to create.");    
    XCTAssertTrue( [newFoo.array isKindOfClass: [NSArray class]], @"newFoo.array is NOT KindOfClass NSArray!" );    
    XCTAssertTrue( [newFoo.dict isKindOfClass: [NSDictionary class]], @"newFoo.dict is NOT KindOfClass NSDictionary!" );
    
    // Test newFoo collections to be the same size.
    XCTAssertTrue([newFoo.array count] == [self.fooWithCollections.array count], @"newFoo.array count is not wrong!" );
    XCTAssertTrue([newFoo.dict count] == [self.fooWithCollections.dict count], @"newFoo.dict count is not wrong!" );
    
    XCTAssertTrue([ self array:newFoo.array isEqualTo: self.fooWithCollections.array], @"newFoo.array is not equal with the original!" );
    XCTAssertTrue([ self dict: newFoo.dict isEqualTo: self.fooWithCollections.dict], @"newFoo.dict = %@, self.foo.dict = %@", newFoo.dict, self.fooWithCollections.dict  );
}

- (void) testCustomObjectsCollectionInMemory
{
    // Prepare custom object for collections.
    Foo *one = [Foo new];
    Foo *two = [Foo new];
    Foo *three = [Foo new];
    one.integerValue = 1;
    two.integerValue = 2;
    three.integerValue = 3;
    
    Bar *obj1 = [Bar new];
    Bar *obj2 = [Bar new];
    Bar *obj3 = [Bar new];
    obj1.someString = @"object numero uno!";
    obj2.someString = @"object numero dvuno!";
    obj3.someString = @"object numero trino!";
    
    
    // Prepare source foo.
    self.fooWithCollections.array = (NSArray<Foo> *)@[one, two, three];
    self.fooWithCollections.dict = (NSDictionary<Bar> *)@{@"key1": obj1, @"key2": obj2, @"key3": obj3};
    
    
    if ( kAMCFieldTypeCollectionArray != [self.fooWithCollections AMCFieldTypeForValueWithKey: @"array"] )
        XCTFail(@"fieldTypeForValueWithKey: doesn't recognize NSArray as array collection!");
    
    if ( kAMCFieldTypeCollectionHash != [self.fooWithCollections AMCFieldTypeForValueWithKey: @"dict"] )
        XCTFail(@"fieldTypeForValueWithKey: doesn't recognize NSArray as array collection!");
    
    // Save & Load.
    NSDictionary *fooDict = [self.fooWithCollections dictionaryRepresentation];   
    // Create new object from that dictionary.
    FooWithCollections *newFoo = [FooWithCollections objectWithDictionaryRepresentation: fooDict];
    
    // Test newFoo.
    XCTAssertNotNil(newFoo, @"newFoo failed to create.");
    
    if (![[newFoo className] isEqualToString: [FooWithCollections className]])
        XCTFail(@"newFoo should be FooWithCollections!");
    XCTAssertTrue( [newFoo isMemberOfClass: [FooWithCollections class]], @"newFoo is NOT MemberOfClass FooWithCollections!" );
    
    // Test newFoo collections.
    XCTAssertNotNil(newFoo.array, @"newFoo.array failed to create.");
    XCTAssertNotNil(newFoo.dict, @"newFoo.dict failed to create.");    
    XCTAssertTrue( [newFoo.array isKindOfClass: [NSArray class]], @"newFoo.array is NOT KindOfClass NSArray!" );    
    XCTAssertTrue( [newFoo.dict isKindOfClass: [NSDictionary class]], @"newFoo.dict is NOT KindOfClass NSDictionary!" );
    
    // Test newFoo collections to be the same size.
    XCTAssertTrue([newFoo.array count] == [self.fooWithCollections.array count], @"newFoo.array count is not wrong!" );
    XCTAssertTrue([newFoo.dict count] == [self.fooWithCollections.dict count], @"newFoo.dict count is not wrong!" );
    
    XCTAssertTrue([ self array:newFoo.array isEqualTo: self.fooWithCollections.array], @"newFoo.array is not equal with the original!" );
    XCTAssertTrue([ self dict: newFoo.dict isEqualTo: self.fooWithCollections.dict], @"newFoo.dict is not equal with the original!" );
}

- (void) testCustomObjectsCollectionInFile
{
    // Prepare custom object for collections.
    Foo *one = [Foo new];
    Foo *two = [Foo new];
    Foo *three = [Foo new];
    one.integerValue = 1;
    two.integerValue = 2;
    three.integerValue = 3;
    
    one.publicBar = [Bar new];
    one.publicBar.someString = @"someString in one.publicBar";
    Bar *onePrivateBar = [Bar new];
    onePrivateBar.someString = @"someString in onePrivateBar";
    [one setValue:onePrivateBar forKey:@"privateBar"];
    
    two.publicBar = [Bar new];
    two.publicBar.someString = @"someString in two.publicBar";
    Bar *twoPrivateBar = [Bar new];
    twoPrivateBar.someString = @"someString in twoPrivateBar";
    [two setValue:twoPrivateBar forKey:@"privateBar"];
    
    Bar *obj1 = [Bar new];
    Bar *obj2 = [Bar new];
    Bar *obj3 = [Bar new];
    obj1.someString = @"object numero uno!";
    obj2.someString = @"object numero dvuno!";
    obj3.someString = @"object numero trino!";
    
    
    
    // Prepare source foo.
    self.fooWithCollections.array = (NSArray<Foo> *)@[one, two, three];
    self.fooWithCollections.dict = (NSDictionary<Bar> *)@{@"key1": obj1, @"key2": obj2, @"key3": obj3};
    
    // Save object representation in PLIXCT & Create new object from that PLIXCT.
    NSString *path = [self testFilePathWithSuffix:@"Custom"];
    NSDictionary *dictRepr =[self.fooWithCollections dictionaryRepresentation];    
    [dictRepr writeToFile: path atomically:YES]; 
    FooWithCollections *newFoo = [FooWithCollections objectWithDictionaryRepresentation: [NSDictionary dictionaryWithContentsOfFile: path]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: path ])
        XCTFail(@"Test file with path = %@ not exist! Dictionary representation = %@", path, dictRepr);
    
    // Test newFoo.
    XCTAssertNotNil(newFoo, @"newFoo failed to create.");
    
    if (![[newFoo className] isEqualToString: [FooWithCollections className]])
        XCTFail(@"newFoo should be FooWithCollections!");
    XCTAssertTrue( [newFoo isMemberOfClass: [FooWithCollections class]], @"newFoo is NOT MemberOfClass FooWithCollections!" );
    
    // Test newFoo collections.
    XCTAssertNotNil(newFoo.array, @"newFoo.array failed to create.");
    XCTAssertNotNil(newFoo.dict, @"newFoo.dict failed to create.");    
    XCTAssertTrue( [newFoo.array isKindOfClass: [NSArray class]], @"newFoo.array is NOT KindOfClass NSArray!" );    
    XCTAssertTrue( [newFoo.dict isKindOfClass: [NSDictionary class]], @"newFoo.dict is NOT KindOfClass NSDictionary!" );
    
    // Test newFoo collections to be the same size.
    XCTAssertTrue([newFoo.array count] == [self.fooWithCollections.array count], @"newFoo.array count is not wrong!" );
    XCTAssertTrue([newFoo.dict count] == [self.fooWithCollections.dict count], @"newFoo.dict count is not wrong!" );
    
    XCTAssertTrue([ self array:newFoo.array isEqualTo: self.fooWithCollections.array], @"self.fooWithCollections.array = %@, newFoo.array = %@", self.fooWithCollections.array, newFoo.array  );
    XCTAssertTrue([ self dict: newFoo.dict isEqualTo: self.fooWithCollections.dict], @"newFoo.dict is not equal with the original!" );
    
    // Test Foo#isEqual & Bar#isEqual for negative reaction
    twoPrivateBar.someString = @"someString in twoPrivateBar messed up";
    XCTAssertFalse([ self array:newFoo.array isEqualTo: self.fooWithCollections.array], @"self.fooWithCollections.array = %@, newFoo.array = %@", self.fooWithCollections.array, newFoo.array  );
    
}

- (void) testCollectionsOfCollectionsInMemory
{
    // Prepare custom objects for collections.
    Foo *one = [Foo new];
    Foo *two = [Foo new];
    Foo *three = [Foo new];
    one.integerValue = 1;
    two.integerValue = 2;
    three.integerValue = 3;
    
    Bar *obj1 = [Bar new];
    Bar *obj2 = [Bar new];
    Bar *obj3 = [Bar new];
    obj1.someString = @"object numero uno!";
    obj2.someString = @"object numero dvuno!";
    obj3.someString = @"object numero trino!";
    
    // Prepare objects for collections in collections.
    Foo *fourOne = [Foo new];
    Foo *fourTwo = [Foo new];
    Foo *fourThree = [Foo new];
    fourOne.integerValue = 41;
    fourTwo.integerValue = 42;
    fourThree.integerValue = 43;
    
    Bar *obj4obj1 = [Bar new];
    Bar *obj4obj2 = [Bar new];
    Bar *obj4obj3 = [Bar new];
    obj4obj1.someString = @"incapsulated dict. Object - 1";
    obj4obj2.someString = @"incapsulated dict. Object - 2";
    obj4obj3.someString = @"incapsulated dict. Object - 3";
    
    // Prepare collections in collections.
    NSArray *four = [NSArray arrayWithObjects:fourOne, fourTwo, fourThree, nil];
    NSDictionary *obj4 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:obj4obj1, obj4obj2,obj4obj3, nil] 
                                                     forKeys:[NSArray arrayWithObjects:@"obj4key1",@"obj4key2",@"obj4key3", nil]];
    
    
    // Prepare source foo.
    self.fooWithCollections.array = (NSArray<Foo> *)@[one, two, three, four];
    self.fooWithCollections.dict = (NSDictionary<Bar> *)@{@"key1": obj1, @"key2": obj2, @"key3": obj3, @"key4-collection": obj4};
    
    // Save & Load.
    NSDictionary *fooDict = [self.fooWithCollections dictionaryRepresentation];   
    // Create new object from that dictionary.
    FooWithCollections *newFoo = [FooWithCollections objectWithDictionaryRepresentation: fooDict];
    
    // Test newFoo.
    XCTAssertNotNil(newFoo, @"newFoo failed to create.");
    
    if (![[newFoo className] isEqualToString: [FooWithCollections className]])
        XCTFail(@"newFoo should be FooWithCollections!");
    XCTAssertTrue( [newFoo isMemberOfClass: [FooWithCollections class]], @"newFoo is NOT MemberOfClass FooWithCollections!" );
    
    // Test newFoo collections.
    XCTAssertNotNil(newFoo.array, @"newFoo.array failed to create.");
    XCTAssertNotNil(newFoo.dict, @"newFoo.dict failed to create.");    
    XCTAssertTrue( [newFoo.array isKindOfClass: [NSArray class]], @"newFoo.array is NOT KindOfClass NSArray!" );    
    XCTAssertTrue( [newFoo.dict isKindOfClass: [NSDictionary class]], @"newFoo.dict is NOT KindOfClass NSDictionary!" );
    
    // Test newFoo collections to be the same size.    
    XCTAssertTrue([newFoo.array count] == [self.fooWithCollections.array count], @"newFoo.array count is wrong!" );
    XCTAssertTrue([newFoo.dict count] == [self.fooWithCollections.dict count], @"newFoo.dict count is wrong!" );

    XCTAssertTrue([ self array:newFoo.array isEqualTo: self.fooWithCollections.array], @"newFoo.array is not equal with the original!" );
    XCTAssertTrue([ self dict: newFoo.dict isEqualTo: self.fooWithCollections.dict], @"newFoo.dict is not equal with the original!" );
}

- (void) testCollectionsOfCollectionsInFile
{
    // Prepare custom objects for collections.
    Foo *one = [Foo new];
    Foo *two = [Foo new];
    Foo *three = [Foo new];
    one.integerValue = 1;
    two.integerValue = 2;
    three.integerValue = 3;
    
    Bar *obj1 = [Bar new];
    Bar *obj2 = [Bar new];
    Bar *obj3 = [Bar new];
    obj1.someString = @"object numero uno!";
    obj2.someString = @"object numero dvuno!";
    obj3.someString = @"object numero trino!";
    
    // Prepare objects for collections in collections.
    Foo *fourOne = [Foo new];
    Foo *fourTwo = [Foo new];
    Foo *fourThree = [Foo new];
    fourOne.integerValue = 41;
    fourTwo.integerValue = 42;
    fourThree.integerValue = 43;
    
    Bar *obj4obj1 = [Bar new];
    Bar *obj4obj2 = [Bar new];
    Bar *obj4obj3 = [Bar new];
    obj4obj1.someString = @"incapsulated dict. Object - 1";
    obj4obj2.someString = @"incapsulated dict. Object - 2";
    obj4obj3.someString = @"incapsulated dict. Object - 3";
    
    // Prepare collections in collections.
    NSArray *four = [NSArray arrayWithObjects:fourOne, fourTwo, fourThree, nil];
    NSDictionary *obj4 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:obj4obj1, obj4obj2,obj4obj3, nil] 
                                                     forKeys:[NSArray arrayWithObjects:@"obj4key1",@"obj4key2",@"obj4key3", nil]];
    
    
    // Prepare source foo.
    self.fooWithCollections.array = (NSArray<Foo> *)@[one, two, three, four];
    self.fooWithCollections.dict = (NSDictionary<Bar> *)@{@"key1": obj1, @"key2": obj2, @"key3": obj3, @"key4-collection": obj4};
    
    // Save object representation in PLIXCT & Create new object from that PLIXCT.
    NSString *path = [self testFilePathWithSuffix:@"CollectionWithCollectionOfCustom"];
    NSDictionary *dictRepr =[self.fooWithCollections dictionaryRepresentation];    
    [dictRepr writeToFile: path atomically:YES]; 
    FooWithCollections *newFoo = [FooWithCollections objectWithDictionaryRepresentation: [NSDictionary dictionaryWithContentsOfFile: path]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: path ])
        XCTFail(@"Test file with path = %@ not exist! Dictionary representation = %@", path, dictRepr);
    
    // Test newFoo.
    XCTAssertNotNil(newFoo, @"newFoo failed to create.");
    
    if (![[newFoo className] isEqualToString: [FooWithCollections className]])
        XCTFail(@"newFoo should be FooWithCollections!");
    XCTAssertTrue( [newFoo isMemberOfClass: [FooWithCollections class]], @"newFoo is NOT MemberOfClass FooWithCollections!" );
    
    // Test newFoo collections.
    XCTAssertNotNil(newFoo.array, @"newFoo.array failed to create.");
    XCTAssertNotNil(newFoo.dict, @"newFoo.dict failed to create.");    
    XCTAssertTrue( [newFoo.array isKindOfClass: [NSArray class]], @"newFoo.array is NOT KindOfClass NSArray!" );    
    XCTAssertTrue( [newFoo.dict isKindOfClass: [NSDictionary class]], @"newFoo.dict is NOT KindOfClass NSDictionary!" );
    
    // Test newFoo collections to be the same size.
    XCTAssertTrue([newFoo.array count] == [self.fooWithCollections.array count], @"newFoo.array count is not wrong!" );
    XCTAssertTrue([newFoo.dict count] == [self.fooWithCollections.dict count], @"newFoo.dict count is not wrong!" );
    
    XCTAssertTrue([ self array:newFoo.array isEqualTo: self.fooWithCollections.array], @"newFoo.array is not equal with the original!" );
    XCTAssertTrue([ self dict: newFoo.dict isEqualTo: self.fooWithCollections.dict], @"newFoo.dict is not equal with the original!" );
}


- (void) testFieldTypeDetection
{
    // Prepare custom object for collections.
    Foo *one = [Foo new];
    Foo *two = [Foo new];
    Foo *three = [Foo new];
    one.integerValue = 1;
    two.integerValue = 2;
    three.integerValue = 3;
    
    Bar *obj1 = [Bar new];
    Bar *obj2 = [Bar new];
    Bar *obj3 = [Bar new];
    obj1.someString = @"object numero uno!";
    obj2.someString = @"object numero dvuno!";
    obj3.someString = @"object numero trino!";
    
    
    // Test immutable collection detection.
    self.fooWithCollections.array = (NSArray<Foo> *)@[one, two, three];
    self.fooWithCollections.dict = (NSDictionary<Bar> *)@{@"key1": obj1, @"key2": obj2, @"key3": obj3};
    
    
    if ( kAMCFieldTypeCollectionArray != [self.fooWithCollections AMCFieldTypeForValueWithKey: @"array"] )
        XCTFail(@"fieldTypeForValueWithKey: doesn't recognize NSArray as array collection!");
    
    if ( kAMCFieldTypeCollectionHash != [self.fooWithCollections AMCFieldTypeForValueWithKey: @"dict"] )
        XCTFail(@"fieldTypeForValueWithKey: doesn't recognize NSDictionary as hash collection!");
    
    // Test mutable collection detection.
    self.fooWithCollections = (FooWithCollections *)[FooWithMutableCollections new];
    self.fooWithCollections.array = (NSArray<Foo> *)@[one, two].mutableCopy;
    [(NSMutableArray *)self.fooWithCollections.array addObject: three ];
    self.fooWithCollections.dict = (NSDictionary<Bar> *)@{@"key1": obj1, @"key2": obj2}.mutableCopy;
    [(NSMutableDictionary *)self.fooWithCollections.dict setObject: obj3 forKey: @"key3" ];
    
    if ( kAMCFieldTypeCollectionArrayMutable != [self.fooWithCollections AMCFieldTypeForValueWithKey: @"array"] )
        XCTFail(@"fieldTypeForValueWithKey: doesn't recognize NSArray as array collection!");
    
    if ( kAMCFieldTypeCollectionHashMutable != [self.fooWithCollections AMCFieldTypeForValueWithKey: @"dict"] )
        XCTFail(@"fieldTypeForValueWithKey: doesn't recognize NSDictionary as hash collection!");
    
    if ( kAMCFieldTypeScalar != [one AMCFieldTypeForValueWithKey:@"integerValue"])
        XCTFail(@"fieldTypeForValueWithKey: doesn't recognize int as scalar/struct!");
    
    if ( kAMCFieldTypeCustomObject != [one AMCFieldTypeForValueWithKey:@"publicBar"])
        XCTFail(@"fieldTypeForValueWithKey: doesn't recognize Bar as Custom!");
}

- (void) testMutableCollections
{
    // Set-up code here.
    self.fooWithCollections = (FooWithCollections *)[FooWithMutableCollections new];
    
    // Prepare custom objects for collections.
    Foo *one = [Foo new];
    Foo *two = [Foo new];
    Foo *three = [Foo new];
    one.integerValue = 1;
    two.integerValue = 2;
    three.integerValue = 3;
    
    Bar *obj1 = [Bar new];
    Bar *obj2 = [Bar new];
    Bar *obj3 = [Bar new];
    obj1.someString = @"object numero uno!";
    obj2.someString = @"object numero dvuno!";
    obj3.someString = @"object numero trino!";
    
    // Prepare objects for collections in collections.
    Foo *fourOne = [Foo new];
    Foo *fourTwo = [Foo new];
    Foo *fourThree = [Foo new];
    fourOne.integerValue = 41;
    fourTwo.integerValue = 42;
    fourThree.integerValue = 43;
    
    Bar *obj4obj1 = [Bar new];
    Bar *obj4obj2 = [Bar new];
    Bar *obj4obj3 = [Bar new];
    obj4obj1.someString = @"incapsulated dict. Object - 1";
    obj4obj2.someString = @"incapsulated dict. Object - 2";
    obj4obj3.someString = @"incapsulated dict. Object - 3";
    
    // Prepare collections in collections.
    NSArray *four = [NSArray arrayWithObjects:fourOne, fourTwo, fourThree, nil];
    NSDictionary *obj4 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:obj4obj1, obj4obj2,obj4obj3, nil] 
                                                     forKeys:[NSArray arrayWithObjects:@"obj4key1",@"obj4key2",@"obj4key3", nil]];
    
    
    // Prepare source foo.
    self.fooWithCollections.array = (NSArray<Foo> *)@[one, two, three, four];
    self.fooWithCollections.dict = (NSDictionary<Bar> *)@{@"key1": obj1, @"key2": obj2, @"key3": obj3, @"key4-collection": obj4};

    // Save object representation in PLIXCT & Create new object from that PLIXCT.
    NSString *path = [self testFilePathWithSuffix:@"CollectionWithCollectionOfCustom"];
    NSDictionary *dictRepr =[self.fooWithCollections dictionaryRepresentation];    
    [dictRepr writeToFile: path atomically:YES]; 
    FooWithCollections *newFoo = [FooWithMutableCollections objectWithDictionaryRepresentation: [NSDictionary dictionaryWithContentsOfFile: path]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: path ])
        XCTFail(@"Test file with path = %@ not exist! Dictionary representation = %@", path, dictRepr);
    
    // Test newFoo.
    XCTAssertNotNil(newFoo, @"newFoo failed to create.");
    
    if (![[newFoo className] isEqualToString: [FooWithMutableCollections className]])
        XCTFail(@"newFoo should be FooWithCollections!");
    XCTAssertTrue( [newFoo isMemberOfClass: [FooWithMutableCollections class]], @"newFoo is NOT MemberOfClass FooWithCollections!" );
    
    // Test newFoo collections.
    XCTAssertNotNil(newFoo.array, @"newFoo.array failed to create.");
    XCTAssertNotNil(newFoo.dict, @"newFoo.dict failed to create.");    
    XCTAssertTrue( [newFoo.array isKindOfClass: [NSArray class]], @"newFoo.array is NOT KindOfClass NSArray!" );    
    XCTAssertTrue( [newFoo.dict isKindOfClass: [NSDictionary class]], @"newFoo.dict is NOT KindOfClass NSDictionary!" );
    
    // Test newFoo collections to be the same size.
    XCTAssertTrue([newFoo.array count] == [self.fooWithCollections.array count], @"newFoo.array count is not wrong!" );
    XCTAssertTrue([newFoo.dict count] == [self.fooWithCollections.dict count], @"newFoo.dict count is not wrong!" );
    
    XCTAssertTrue([ self array:newFoo.array isEqualTo: self.fooWithCollections.array], @"newFoo.array is not equal with the original!" );
    XCTAssertTrue([ self dict: newFoo.dict isEqualTo: self.fooWithCollections.dict], @"newFoo.dict is not equal with the original!" );
    
    // Test if newFoo has mutable collections
    XCTAssertTrue([newFoo.array isKindOfClass: [NSMutableArray class]], @"newFoo.array = %@", newFoo.array);
    XCTAssertTrue([newFoo.dict isKindOfClass: [NSMutableDictionary class]], @"newFoo.dict = %@", newFoo.dict);
    
    FooWithMutableCollections *newFooMutable = (FooWithMutableCollections *) newFoo;
    NSUInteger prevArrayCount = [newFoo.array count];
    NSUInteger prevDictCount = [newFoo.dict count];
    
    @try {
        [newFooMutable.array addObject: @"blablaObject"];
        [newFooMutable.dict setObject:@"testingMutable" forKey:@"addedAfter"];
        
        XCTAssertFalse([newFoo.array count] == prevArrayCount, @"");
        XCTAssertFalse([newFoo.dict count] == prevDictCount, @"");
    }
    @catch (NSException *exception) {
        XCTFail(@"Mutable collections crashed while trying to modify them");
    }
}

- (void) testCustomCollection
{
    // Set-up code here.
    self.fooWithCollections = (FooWithCollections *)[FooWithCustomCollection new];
    
    // Prepare custom objects for collections.
    Foo *one = [Foo new];
    Foo *two = [Foo new];
    Foo *three = [Foo new];
    one.integerValue = 1;
    two.integerValue = 2;
    three.integerValue = 3;
    
    // Prepare objects for collections in collections.
    Foo *fourOne = [Foo new];
    Foo *fourTwo = [Foo new];
    Foo *fourThree = [Foo new];
    fourOne.integerValue = 41;
    fourTwo.integerValue = 42;
    fourThree.integerValue = 43;
    
    // Prepare collections in collections.
    NSArray *four = [NSArray arrayWithObjects:fourOne, fourTwo, fourThree, nil];
    
    
    // Prepare source foo.
    self.fooWithCollections.array = (NSArray<Foo> *)[NSArray arrayWithObjects: one, two, three, four, nil];
    
    // Save object representation in PLIXCT & Create new object from that PLIXCT.
    NSString *path = [self testFilePathWithSuffix:@"CCArray"];
    NSDictionary *dictRepr =[self.fooWithCollections dictionaryRepresentation];    
    [dictRepr writeToFile: path atomically:YES]; 
    FooWithCustomCollection *newFoo = [FooWithCustomCollection objectWithDictionaryRepresentation: [NSDictionary dictionaryWithContentsOfFile: path]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: path ])
        XCTFail(@"Test file with path = %@ not exist! Dictionary representation = %@", path, dictRepr);
    
    // Test newFoo.
    XCTAssertNotNil(newFoo, @"newFoo failed to create.");
    
    if (![[newFoo className] isEqualToString: [FooWithCustomCollection className]])
        XCTFail(@"newFoo should be FooWithCustomCollection!");
    XCTAssertTrue( [newFoo isMemberOfClass: [FooWithCustomCollection class]], @"newFoo is NOT MemberOfClass FooWithCustomCollection!" );
    
    // Test newFoo collections.
    XCTAssertNotNil(newFoo.array, @"newFoo.array failed to create.");
    
    // Test newFoo collections to be the same size.
    XCTAssertTrue([newFoo.array count] == [self.fooWithCollections.array count], @"newFoo.array count is not wrong!" );
    
    XCTAssertTrue([ self array:(NSArray *)newFoo.array isEqualTo: (NSArray *)self.fooWithCollections.array], @"newFoo.array is not equal with the original!" );
    
    // Test if newFoo has mutable collections
    FooWithMutableCollections *newFooMutable = (FooWithMutableCollections *) newFoo;
    NSUInteger prevArrayCount = [newFoo.array count];
    
    @try {
        [newFooMutable.array addObject: @"blablaObject"];
        
        XCTAssertFalse([newFoo.array count] == prevArrayCount, @"");
    }
    @catch (NSException *exception) {
        XCTFail(@"Mutable custom collection crashed while trying to modify them");
    }
    
    // Save again.
    NSString *path2 = [self testFilePathWithSuffix:@"CCArrayModified"];
    dictRepr =[newFooMutable dictionaryRepresentation];    
    [dictRepr writeToFile: path2 atomically:YES];
    
    // Test that file exists after saving modified CCArray.
    if (![[NSFileManager defaultManager] fileExistsAtPath: path2 ])
        XCTFail(@"Test file with path = %@ not exist! Dictionary representation = %@", path, dictRepr);
    
    // Test if its modified in new file.
    FooWithCustomCollection *newFooModified = [FooWithCustomCollection objectWithDictionaryRepresentation: [NSDictionary dictionaryWithContentsOfFile: path2]];
    
    // Test newFooModified.
    XCTAssertNotNil(newFooModified, @"newFoo failed to create.");
    
    // Test last added object equality in CCArray.
    XCTAssertTrue([[newFooModified.array objectAtIndex: 4] isEqual: [newFooMutable.array objectAtIndex: 4]], @"newFooModified.array[4] = %@ newFooMutable.array[4] = %@", [newFooModified.array objectAtIndex: 4], [newFooMutable.array objectAtIndex: 4]);
        
}

- (void)tearDown
{
    // Tear-down code here.
    self.fooWithCollections = nil;
    
    [super tearDown];
}

@end
