//
//  enhanceTests.m
//  enhanceTests
//
//  Created by Adam Yanalunas on 11/11/2014.
//  Copyright (c) 2014 Adam Yanalunas. All rights reserved.
//

SpecBegin(InitialSpecs)

describe(@"these will pass", ^{
    
    it(@"can do maths", ^{
        expect(1).beLessThan(23);
    });
    
    it(@"can read", ^{
        expect(@"team").toNot.contain(@"I");
    });
});

SpecEnd
