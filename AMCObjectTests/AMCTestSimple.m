//
//  AMCTestSimple.m
//  AutoMagicCodingTests
//
//   31.08.11.
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

#import "AMCTestSimple.h"
#import "AMCObject.h"
#import "ObjectsForTests/Foo.h"
#import "ObjectsForTests/Bar.h"
#import "ObjectsForTests/FooWithSctructs.h"

#ifdef __MAC_OS_X_VERSION_MAX_ALLOWED
    #define NSStringFromCGRect(X) NSStringFromRect(NSRectFromCGRect(X))
#endif

@implementation AMCTestSimple
@synthesize foo = _foo;

- (void)setUp
{
    [super setUp];
    
    // Prepare Foo class - that we will serialize & deserialize in-memory.
    Foo *foo = [Foo new];
    foo.publicBar = [Bar new];
    foo.integerValue = 17;
    Bar *privateBarInFoo = [Bar new];
    [foo setValue: privateBarInFoo forKey:@"privateBar"];
    
    // Prepare inside bar objects in Foo.
    foo.publicBar.someString = @"Some Randooooom String! =)";
    privateBarInFoo.someString = @"Some another random string - this time it's int private bar!";
    
    // self Foo.
    self.foo = foo;
}

- (void)tearDown
{
    // Release Foo,
    self.foo = nil;
    
    [super tearDown];
}

- (void) testInMemory
{    
    // Save object representation in NSDictionary.
    NSDictionary *fooDict = [self.foo dictionaryRepresentation];
    
    // Create new object from that dictionary.
    Foo *newFoo = [Foo objectWithDictionaryRepresentation: fooDict];
    
    // Test Foo
    XCTAssertNotNil(newFoo, @"newFoo failed to create.");
    
    if (![[newFoo className] isEqualToString: [Foo className]])
        XCTFail(@"newFoo should be Foo!");
    XCTAssertTrue( [newFoo isMemberOfClass: [Foo class]], @"isMemberOfClass not working: Foo isn't Foo according to it." );
    
    // Test Foo.publicBar
    XCTAssertNotNil(newFoo.publicBar, @"newFoo.publicBar failed to create.");
    
    if (![[newFoo.publicBar className] isEqualToString: [Bar className]])
        XCTFail(@"newFoo.publicBar should be Bar!");
    XCTAssertTrue( [newFoo.publicBar isMemberOfClass: [Bar class]], @"isMemberOfClass not working: Bar isn't Bar according to it." );
    
    // Test object equality.
    XCTAssertTrue(newFoo.integerValue == self.foo.integerValue, @"foo.integerValue value corrupted during save/load.");
    XCTAssertTrue([newFoo.publicBar.someString isEqualToString: self.foo.publicBar.someString],@"foo.bar.someString corrupted during save/load.");
    
    // Test addition to keys - ivars without public properties.
    XCTAssertNotNil([newFoo valueForKey: @"privateBar"], @"newFoo.privateBar failed to create.");
    
    NSString *oldPrivateString = ((Bar *)[self.foo valueForKey:@"privateBar"]).someString;
    NSString *newPrivateString = ((Bar *)[newFoo valueForKey:@"privateBar"]).someString;
    XCTAssertTrue([oldPrivateString isEqualToString: newPrivateString],@"foo.privateBar.someString corrupted during save/load.");
}

- (void) testInFile
{
    // Save object representation in PLIXCT & Create new object from that PLIXCT.
    NSString *path = [self testFilePathWithSuffix:nil];
    NSDictionary *dictRepr =[self.foo dictionaryRepresentation];
    [dictRepr writeToFile: path atomically:YES]; 
    Foo *newFoo = [[Foo objectWithDictionaryRepresentation: [NSDictionary dictionaryWithContentsOfFile: path]] self];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: path ])
        XCTFail(@"Test file with path = %@ not exist! Dictionary representation = %@", path, dictRepr);
    
    // Test Foo
    XCTAssertNotNil(newFoo, @"newFoo failed to create.");
    
    if (![[newFoo className] isEqualToString: [Foo className]])
        XCTFail(@"newFoo should be Foo!");
    XCTAssertTrue( [newFoo isMemberOfClass: [Foo class]], @"isMemberOfClass not working: Foo isn't Foo according to it." );
    
    // Test Foo.publicBar
    XCTAssertNotNil(newFoo.publicBar, @"newFoo.publicBar failed to create.");
    
    if (![[newFoo.publicBar className] isEqualToString: [Bar className]])
        XCTFail(@"newFoo.publicBar should be Bar!");
    XCTAssertTrue( [newFoo.publicBar isMemberOfClass: [Bar class]], @"isMemberOfClass not working: Bar isn't Bar according to it." );
    
    // Test object equality.
    XCTAssertTrue(newFoo.integerValue == self.foo.integerValue, @"foo.integerValue value corrupted during save/load.");
    XCTAssertTrue([newFoo.publicBar.someString isEqualToString: self.foo.publicBar.someString],@"foo.bar.someString corrupted during save/load.");
    
    // Test addition to keys - ivars without public properties.
    XCTAssertNotNil([newFoo valueForKey: @"privateBar"], @"newFoo.privateBar failed to create.");
    
    NSString *oldPrivateString = ((Bar *)[self.foo valueForKey:@"privateBar"]).someString;
    NSString *newPrivateString = ((Bar *)[newFoo valueForKey:@"privateBar"]).someString;
    XCTAssertTrue([oldPrivateString isEqualToString: newPrivateString],@"foo.privateBar.someString corrupted during save/load.");
}

- (void) testStructsInFile
{
    // Prepare and save Foo in Dict.
    FooWithSctructs *foo = [FooWithSctructs new];
    foo.point = CGPointMake(15.0f, 16.0f);
    foo.size = CGSizeMake(154.45f, 129.0f);
    foo.rect = CGRectMake(39.0f, 235.0f, 1233.09f, 124.0f);
    NSDictionary *fooDict = [foo dictionaryRepresentation];
    
    // Save object representation in PLIXCT & Create new object from that PLIXCT.
    NSString *path = [self testFilePathWithSuffix:@"Struct"];
    [fooDict writeToFile: path atomically:YES];
    // Load newFoo from dict
    FooWithSctructs *newFoo = [[FooWithSctructs objectWithDictionaryRepresentation: [NSDictionary dictionaryWithContentsOfFile: path]] self];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: path ])
        XCTFail(@"Test file with path = %@ not exist! Dictionary representation = %@", path, fooDict);
    
    // Test Foo
    XCTAssertNotNil(newFoo, @"newFoo failed to create.");
    
    if (![[newFoo className] isEqualToString: [FooWithSctructs className]])
        XCTFail(@"newFoo should be FooWithStructs!");
    XCTAssertTrue( [newFoo isMemberOfClass: [FooWithSctructs class]], @"isMemberOfClass not working: Foo isn't FooWithSctructs according to it." );
    
    // Test foo's equality.
    XCTAssertTrue( CGSizeEqualToSize(foo.size, newFoo.size), @"foo.size = {%f, %f} newFoo.size = {%f, %f} ",
                 foo.size.width, foo.size.height, newFoo.size.width, newFoo.size.height);
    XCTAssertTrue( CGPointEqualToPoint(foo.point, newFoo.point),@"foo.point = {%f, %f} newFoo.point = {%f, %f}",
                 foo.point.x, foo.point.y, newFoo.point.x, newFoo.point.y);
    XCTAssertTrue( CGRectEqualToRect(foo.rect, newFoo.rect), @"Foo.rect = %@ newFoo.rect = %@", NSStringFromCGRect(foo.rect), NSStringFromCGRect(newFoo.rect) );
}

- (void) testStructsInMemory
{
    // Prepare and save Foo in Dict.
    FooWithSctructs *foo = [FooWithSctructs new];
    foo.point = CGPointMake(15.0f, 16.0f);
    foo.size = CGSizeMake(154.45f, 129.0f);
    foo.rect = CGRectMake(39.0f, 235.0f, 1233.09f, 124.0f);
    NSDictionary *fooDict = [foo dictionaryRepresentation];
    
    // Load newFoo from dict
    FooWithSctructs *newFoo = [[FooWithSctructs objectWithDictionaryRepresentation: fooDict] self];
    
    // Test foo's equality.
    XCTAssertTrue( CGSizeEqualToSize(foo.size, newFoo.size), @"foo.size = {%f, %f} newFoo.size = {%f, %f} ",
                 foo.size.width, foo.size.height, newFoo.size.width, newFoo.size.height);
    XCTAssertTrue( CGPointEqualToPoint(foo.point, newFoo.point),@"foo.point = {%f, %f} newFoo.point = {%f, %f}",
                 foo.point.x, foo.point.y, newFoo.point.x, newFoo.point.y);
    XCTAssertTrue( CGRectEqualToRect(foo.rect, newFoo.rect), @"Foo.rect = %@ newFoo.rect = %@", NSStringFromCGRect(foo.rect), NSStringFromCGRect(newFoo.rect) );
}

- (void) testStructTypeDetection
{
    FooWithSctructs *foo = [FooWithSctructs new];

    NSString *structNamePoint = AMCPropertyStruct([foo class], @"point");
    NSString *structNameRect = AMCPropertyStruct([foo class], @"rect");
    NSString *structNameSize = AMCPropertyStruct([foo class], @"size");
    NSString *structNameCustom = AMCPropertyStruct([foo class], @"customStruct");
    
    XCTAssertTrue([structNamePoint isEqualToString: @"CGPoint"], @"structNamePoint = %@", structNamePoint );
    XCTAssertTrue([structNameSize isEqualToString: @"CGSize"], @"structNameSize = %@", structNameSize );
    XCTAssertTrue([structNameRect isEqualToString: @"CGRect"], @"structNameSize = %@", structNameRect );
    XCTAssertTrue([structNameCustom isEqualToString: @"CustomStruct"], @"structNameCustom = %@", structNameCustom );
}

- (void) testCustomStructInMemory
{
    FooWithSctructs *foo = [FooWithSctructs new];
    foo.point = CGPointMake(15.0f, 16.0f);
    foo.size = CGSizeMake(154.45f, 129.0f);
    foo.rect = CGRectMake(39.0f, 235.0f, 1233.09f, 124.0f);
    
    CustomStruct custom;
    custom.d = 0.578;
    custom.f = 0.3456f;
    custom.i = -20;
    custom.ui = 55;
    foo.customStruct = custom;
    
    NSDictionary *fooDict = [foo dictionaryRepresentation];
    
    
    FooWithSctructs *newFoo = [FooWithSctructs objectWithDictionaryRepresentation: fooDict];
    
    XCTAssertTrue(newFoo.customStruct.ui == foo.customStruct.ui, 
                 @"newFoo.customStruct.ui should be %d, but it's %d", foo.customStruct.ui, newFoo.customStruct.ui );
    
    XCTAssertTrue(newFoo.customStruct.d == foo.customStruct.d, 
                 @"newFoo.customStruct.d should be %f, but it's %f", foo.customStruct.d, newFoo.customStruct.d );
    
    XCTAssertTrue(newFoo.customStruct.f == foo.customStruct.f, 
                 @"newFoo.customStruct.f should be %f, but it's %f", foo.customStruct.f, newFoo.customStruct.f );
    
    XCTAssertTrue(newFoo.customStruct.i == foo.customStruct.i, 
                 @"newFoo.customStruct.i should be %d, but it's %d", foo.customStruct.i, newFoo.customStruct.i );
}

- (void) testCustomStructInFile
{
    FooWithSctructs *foo = [FooWithSctructs new];
    foo.point = CGPointMake(15.0f, 16.0f);
    foo.size = CGSizeMake(154.45f, 129.0f);
    foo.rect = CGRectMake(39.0f, 235.0f, 1233.09f, 124.0f);
    
    CustomStruct custom;
    custom.d = 0.578;
    custom.f = 0.3456f;
    custom.i = -20;
    custom.ui = 55;
    foo.customStruct = custom;
    
    NSDictionary *fooDict = [foo dictionaryRepresentation];
    NSString *path = [self testFilePathWithSuffix:@"CustomStruct"];
    [fooDict writeToFile: path atomically:YES];
   
    // Load newFoo from dict
    FooWithSctructs *newFoo = [[FooWithSctructs objectWithDictionaryRepresentation: [NSDictionary dictionaryWithContentsOfFile: path]] self];
    
    XCTAssertTrue(newFoo.customStruct.ui == foo.customStruct.ui, 
                 @"newFoo.customStruct.ui should be %d, but it's %d", foo.customStruct.ui, newFoo.customStruct.ui );
    
    XCTAssertTrue(newFoo.customStruct.d == foo.customStruct.d, 
                 @"newFoo.customStruct.d should be %f, but it's %f", foo.customStruct.d, newFoo.customStruct.d );
    
    XCTAssertTrue(newFoo.customStruct.f == foo.customStruct.f, 
                 @"newFoo.customStruct.f should be %f, but it's %f", foo.customStruct.f, newFoo.customStruct.f );
    
    XCTAssertTrue(newFoo.customStruct.i == foo.customStruct.i, 
                 @"newFoo.customStruct.i should be %d, but it's %d", foo.customStruct.i, newFoo.customStruct.i );
}

- (void) testAMCKeysForDictionaryRepresentation
{
    // Get AMC Keys.
    BarBarBar *barbarbar = [BarBarBar new];
    NSArray *keys = [barbarbar AMCKeysForDictionaryRepresentation];
    
    // Test that there's right amount of keys.
    NSArray *expectedKeys = [NSArray arrayWithObjects:@"someString", @"someOtherString", @"thirdString", nil];
    XCTAssertTrue([expectedKeys isEqual: keys], @"ExpectedKeys = %@, but got Keys = %@", expectedKeys, keys);
}

// No additional ...InFile test needed, cause we use same objects and if other tests
// pass - no need to test can these objects be saved to file or not.
- (void) testLoadValueInMemory
{
    // Prepare objects for test with scalar, customObject, struct & customStruct.
    Foo *foo = [Foo new];
    foo.publicBar = [Bar new];//< Custom Object
    foo.publicBar.someString = @"somestring";  //< Scalar in Custom Object.
    foo.integerValue = 15; //< Scalar.
    
    FooWithSctructs *fooWithStructs = [FooWithSctructs new];
    fooWithStructs.point = CGPointMake(156, 12.5f); // < Struct
    CustomStruct custom = {26, 26.1f, 26.2, -9};
    fooWithStructs.customStruct = custom;
    
    // Prepare dictionary representation of these objects.
    NSDictionary *fooRepresentation = [foo dictionaryRepresentation];
    NSDictionary *fooWithStructsRepresentation = [fooWithStructs dictionaryRepresentation];
    
    // Alloc new objects, that will be used to test -loadValueForKey:fromDictionaryRepresentation:
    Foo *newFoo = [Foo alloc];
    Bar *newBar = [Bar alloc]; //< will test how to create independent custom object from included custom object's representation.
    FooWithSctructs *newFooWithStructs = [FooWithSctructs alloc];
    
    
    // Load one value at time and test that other values aren't loaded.
   
    // IntegerValue - scalar.
    XCTAssertFalse(newFoo.integerValue == 15, @"newFoo already has integerValue loaded, but it shouldn't!");
    [newFoo loadValueForKey:@"integerValue" fromDictionaryRepresentation: fooRepresentation];
    XCTAssertTrue(newFoo.integerValue == 15, @"newFoo.integerValue = %d", newFoo.integerValue);
    
    // PublicBar - Custom Object.
    XCTAssertFalse(newFoo.publicBar != nil, @"Bar shouldn't be loaded at this step!");
    [newFoo loadValueForKey:@"publicBar" fromDictionaryRepresentation:fooRepresentation];
    XCTAssertNotNil(newFoo.publicBar, @"Bar should be loaded!");
    XCTAssertTrue([newFoo.publicBar.someString isEqualToString: @"somestring"], @"newFoo.publicBar.someString = %@", newFoo.publicBar.someString);
    
    // PublicBar as independent object.
    XCTAssertNil(newBar.someString, @"newBar.someString shouldn't be loaded at this step!");
    NSDictionary *publicBarInFooDictionary = [fooRepresentation objectForKey:@"publicBar"];
    [newBar loadValueForKey:@"someString" fromDictionaryRepresentation: publicBarInFooDictionary ];
    XCTAssertTrue([newBar.someString isEqualToString: @"somestring"], @"newBar.someString = %@", newBar.someString);
    
    // CGPoint - non-custom structure.
    XCTAssertFalse(CGPointEqualToPoint( newFooWithStructs.point, CGPointMake(156, 12.5f) ) , @"fooWithStructs.point shouldn't be loaded at this step!");
    [newFooWithStructs loadValueForKey:@"point" fromDictionaryRepresentation: fooWithStructsRepresentation];
    XCTAssertTrue(CGPointEqualToPoint( newFooWithStructs.point, CGPointMake(156, 12.5f) ) , @"fooWithStructs.point failed to load properly!");
    
    // CustomStruct.
    XCTAssertFalse(newFooWithStructs.customStruct.ui == 26 , @"fooWithStructs.customStruct shouldn't be loaded at this step!");
    XCTAssertFalse(newFooWithStructs.customStruct.f == 26.1f , @"fooWithStructs.customStruct shouldn't be loaded at this step!");
    XCTAssertFalse(newFooWithStructs.customStruct.d == 26.2 , @"fooWithStructs.customStruct shouldn't be loaded at this step!");
    XCTAssertFalse(newFooWithStructs.customStruct.i == -9 , @"fooWithStructs.customStruct shouldn't be loaded at this step!");
    [newFooWithStructs loadValueForKey:@"customStruct" fromDictionaryRepresentation:fooWithStructsRepresentation];
    
    XCTAssertTrue(newFooWithStructs.customStruct.ui == 26 , @"fooWithStructs.customStruct shouldn't be loaded at this step!");
    XCTAssertTrue(newFooWithStructs.customStruct.f == 26.1f , @"fooWithStructs.customStruct shouldn't be loaded at this step!");
    XCTAssertTrue(newFooWithStructs.customStruct.d == 26.2 , @"fooWithStructs.customStruct shouldn't be loaded at this step!");
    XCTAssertTrue(newFooWithStructs.customStruct.i == -9 , @"fooWithStructs.customStruct shouldn't be loaded at this step!");
}

@end
