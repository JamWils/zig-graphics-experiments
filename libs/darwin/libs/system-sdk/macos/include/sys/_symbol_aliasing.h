/* Copyright (c) 2010 Apple Inc. All rights reserved.
 * 
 * @APPLE_OSREFERENCE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. The rights granted to you under the License
 * may not be used to create, or enable the creation or redistribution of,
 * unlawful or unlicensed copies of an Apple operating system, or to
 * circumvent, violate, or enable the circumvention or violation of, any
 * terms of an Apple operating system software license agreement.
 * 
 * Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_OSREFERENCE_LICENSE_HEADER_END@
 */

#ifndef _CDEFS_H_
# error "Never use <sys/_symbol_aliasing.h> directly.  Use <sys/cdefs.h> instead."
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 20000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_2_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_2_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 20100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_2_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_2_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 20200
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_2_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_2_2(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 30000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_3_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_3_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 30100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_3_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_3_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 30200
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_3_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_3_2(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 40000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 40100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 40200
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_2(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 40300
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_3(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 50000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_5_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_5_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 50100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_5_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_5_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 60000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_6_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_6_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 60100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_6_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_6_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 70000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_7_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_7_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 70100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_7_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_7_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 80000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 80100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 80200
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_2(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 80300
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_3(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 80400
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_4(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 90000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 90100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 90200
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_2(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 90300
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_3(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 100000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 100100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 100200
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_2(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 100300
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_3(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 110000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 110100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 110200
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_2(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 110300
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_3(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 110400
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_4(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 120000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 120100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 120200
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_2(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 120300
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_3(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 120400
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_4(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 130000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 130100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 130200
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_2(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 130300
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_3(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 130400
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_4(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 130500
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_5(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_5(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 130600
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_6(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_6(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 130700
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_7(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_7(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 140000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 140100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 140200
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_2(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 140300
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_3(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 140500
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_5(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_5(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 140400
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_4(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 140500
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_5(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_5(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 140600
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_6(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_6(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 140700
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_7(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_7(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 140800
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_8(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_8(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 150000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 150100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 150200
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_2(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 150300
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_3(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 150400
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_4(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 150500
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_5(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_5(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 150600
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_6(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_6(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 160000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 160100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 160200
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_2(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 160300
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_3(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 160400
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_4(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 160500
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_5(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_5(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 160600
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_6(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_6(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 160700
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_7(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_7(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 170000
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_17_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_17_0(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 170100
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_17_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_17_1(x)
#endif

#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 170200
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_17_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_17_2(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 1000
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_0(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 1010
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_1(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 1020
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_2(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 1030
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_3(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 1040
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_4(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 1050
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_5(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_5(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 1060
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_6(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_6(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 1070
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_7(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_7(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 1080
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_8(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_8(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 1090
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_9(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_9(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101000
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_10(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_10(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101002
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_10_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_10_2(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101003
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_10_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_10_3(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101100
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_11(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_11(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101102
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_11_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_11_2(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101103
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_11_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_11_3(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101104
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_11_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_11_4(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101200
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_12(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_12(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101201
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_12_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_12_1(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101202
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_12_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_12_2(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101204
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_12_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_12_4(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101300
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_13(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_13(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101301
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_13_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_13_1(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101302
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_13_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_13_2(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101304
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_13_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_13_4(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101400
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_14(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_14(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101401
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_1(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101404
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_4(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101405
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_5(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_5(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101406
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_6(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_6(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101500
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_15(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_15(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101501
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_15_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_15_1(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101504
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_15_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_15_4(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101600
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_16(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_16(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 110000
#define __DARWIN_ALIAS_STARTING_MAC___MAC_11_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_11_0(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 110100
#define __DARWIN_ALIAS_STARTING_MAC___MAC_11_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_11_1(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 110300
#define __DARWIN_ALIAS_STARTING_MAC___MAC_11_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_11_3(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 110400
#define __DARWIN_ALIAS_STARTING_MAC___MAC_11_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_11_4(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 110500
#define __DARWIN_ALIAS_STARTING_MAC___MAC_11_5(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_11_5(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 110600
#define __DARWIN_ALIAS_STARTING_MAC___MAC_11_6(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_11_6(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 120000
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_0(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 120100
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_1(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 120200
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_2(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 120300
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_3(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 120400
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_4(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 120500
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_5(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_5(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 120600
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_6(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_6(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 120700
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_7(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_12_7(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 130000
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_0(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 130100
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_1(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 130100
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_1(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 130200
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_2(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 130300
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_3(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 130400
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_4(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_4(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 130500
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_5(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_5(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 130600
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_6(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_13_6(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 140000
#define __DARWIN_ALIAS_STARTING_MAC___MAC_14_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_14_0(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 140100
#define __DARWIN_ALIAS_STARTING_MAC___MAC_14_1(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_14_1(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 140200
#define __DARWIN_ALIAS_STARTING_MAC___MAC_14_2(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_14_2(x)
#endif

