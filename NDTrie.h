/*
	NDTrie.h

	Created by Nathan Day on 09.20.09 under a MIT-style license. 
	Copyright (c) 2009 Nathan Day

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
 */
/*!
	@header NDTrie
	@abstract Declares the interface for the classes <tt>NDTrie</tt> and <tt>NDMutableTrie</tt>.

	@author Nathan Day
	@date Thursday September 17 2009
 */

#import <Foundation/Foundation.h>

#if TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
#define NDFastEnumerationAvailable
#endif

/*!
	@class NDTrie
	@abstract An immutable trie implemented in Objective-C
	@discussion The purpose of <tt>NDTrie</tt> is store strings in way to quickly retrieving all strings with a common prefix, it could also be used as a set equivelent though whether you would get any performance improvement over <tt>NSSet</tt> would need to be tested, it is possible since NDTrie only needs to deal with <tt>NSString</tt>s. <tt>NDTrie</tt> an immutable class with it's contents being set as creation, for a mutable version use the subclass <tt>NDMutableTrie</tt>. The trie can be though of as a set, with only one unique version of each string is stored in the trie attempts to add a string already contained within the trie have no effect.
	@author  Nathan Day
	@version 1.0
*/
#ifdef NDFastEnumerationAvailable
@interface NDTrie : NSObject <NSCopying,NSMutableCopying,NSFastEnumeration>
#else
@interface NDTrie : NSObject <NSCopying,NSMutableCopying>
#endif

/*!
	@method trie
	@abstract Create a new empty trie.
	@discussion This methods is only really useful for creating <tt>NDMutableTrie</tt>
	@result A new empty <tt>NDTrie</tt>
 */
+ (id)trie;
/*!
	@method trieWithArray:
	@abstract Create a new trie from the contents of an <tt>NSArray</tt>.
	@discussion The new trie contains the strings contained within <tt><i>array</i></tt>, duppicates with the array are allowed but only one will be added.
	@param array An array of strings, if an object within the array is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
 */
+ (id)trieWithArray:(NSArray *)array;
/*!
	@method trieWithDictionary:
	@abstract Create a new trie from the contents of an <tt>NSDictionary</tt>.
	@discussion The new trie contains the objects and keys contained within <tt><i>idctionary</i></tt>.
	@param dictionary A dictionary of objects with string keys, if a key within the dictionary is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
 */
+ (id)trieWithDictionary:(NSDictionary *)dictionary;
/*!
	@method trieWithTrie:
	@abstract Create a new trie from the contents of an <tt>NDTrie</tt>.
	@discussion The new trie contains the strings contained within <tt><i>anotherTrie</i></tt>.
	@param array An trie to duplicates.
 */
+ (id)trieWithTrie:(NDTrie *)anotherTrie;
/*!
	@method trieWithStrings:
	@abstract Create a new trie from a list of <tt>NSString</tt>s.
	@discussion The new trie contains the strings contained within the list, if an object within the array is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown. 
	@param firstString The first string of a list of nil terminated strings, if an object within the list is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
 */
+ (id)trieWithStrings:(NSString *)firstString, ... NS_REQUIRES_NIL_TERMINATION;
/*!
	@method trieWithObjectsAndKeys:
	@abstract Create a new trie from a list of objects and keys.
	@discussion The new trie contains the objects and keys contained within the list, if a key within the array is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown. 
	@param firstObject A list of objects and keys
 */
+ (id)trieWithObjectsAndKeys:(id)firstObject , ... NS_REQUIRES_NIL_TERMINATION;
/*!
	@method trieWithContentsOfFile:
	@abstract Create a new trie with the contents of a file.
	@discussion Attempts to create an NSArray with the contents of the file at <tt><i>path</i></tt> and then passes the array to <tt>-[NDTrie initWithArray:]</tt>, if an object within the file is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
	@param path A path to a property list file generated from a <tt>NDTrie</tt> or <tt>NSArray</tt>
 */
+ (id)trieWithContentsOfFile:(NSString *)path;
/*!
	@method trieWithContentsOfURL:
	@abstract Create a new trie with the contents of a file.
	@discussion Attempts to create an NSArray with the contents of the file at <tt><i>url</i></tt> and then passes the array to <tt>-[NDTrie initWithArray:]</tt>, if an object within the file is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
	@param url A file url to a property list file generated from a <tt>NDTrie</tt> or <tt>NSArray</tt>
 */
+ (id)trieWithContentsOfURL:(NSURL *)url;
/*!
	@method trieWithStrings:count:
	@abstract Create a new trie with the content sof a c array.
	@discussion Creates and returns a trie that includes a given number of strings from a given C array.
	@param strings A C array of <tt>NSString</tt>s
	@param count Tbe number of <tt>NSString</tt>s in the c array <tt><i>strings</i></tt>
 */
+ (id)trieWithStrings:(const NSString **)strings count:(NSUInteger)count;
/*!
	@method trieWithObjects:forKeys:count:
	@abstract Create a new trie with the content sof of a c array.
	@discussion Creates and returns a trie that includes a given number of objects  and keys from a given C array.
	@param objects a c array of objects
	@param keys a c array of <tt>NSString</tt>s
	@param count The number of objects and keys
 */
+ (id)trieWithObjects:(id *)objects forKeys:(NSString **)keys count:(NSUInteger)count;
/*!
	@method initWithArray:
	@abstract Initialise a trie with the contents of an <tt>NSArray</tt>.
	@discussion The trie will contain the strings contained within <tt><i>array</i></tt>, duplicates strings are allowed but only one will be added.
	@param array An array of strings, if an object within the array is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
 */
- (id)initWithArray:(NSArray *)array;
/*!
	@method initWithDictionary:
	@abstract Initialise a trie with the contents of an <tt>NSDictionary</tt>.
	@discussion The trie will contain the objects and keys contained within <tt><i>dictionary</i></tt>.
	@param dictionary An dictionary of objects and keys, if a key within the dictionary is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
 */
- (id)initWithDictionary:(NSDictionary *)dictionary;
/*!
	@method initWithTrie:
	@abstract Initialise a trie with the contents of another <tt>NDTrie</tt>.
	@discussion The trie will contain the strings contained within <tt><i>anotherTrie</i></tt>.
	@param array An array of strings.
 */
- (id)initWithTrie:(NDTrie *)anotherTrie;
/*!
	@method initWithStrings:
	@abstract Initialise a trie with a list of <tt>NSString</tt>s
	@discussion The order of th strings is ignored, duplicates will be ignored.
	@param firstString The first string of a list of nil terminated strings, if an object within the list is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
 */
- (id)initWithStrings:(NSString *)firstString, ... NS_REQUIRES_NIL_TERMINATION;
/*!
	@method initWithObjectsAndKeys:
	@abstract Initialise a trie with a list of objects and keys.
	@discussion The object and key pairs are added to the reciever, if a key within the list is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
	@param firstObject A list of objects and key paris.
 */
- (id)initWithObjectsAndKeys:(id)firstObject , ... NS_REQUIRES_NIL_TERMINATION;
/*!
	@method initWithContentsOfFile:
	@abstract Initialise a trie with contents of a file.
	@discussion Attempts to create an NSArray with the contents of the file and then passes the array to <tt>-[NDTrie initWithArray:]</tt>.
	@param path A path to a property list file generated from a <tt>NDTrie</tt> or <tt>NSArray</tt>
 */
- (id)initWithContentsOfFile:(NSString *)path;
/*!
	@method initWithContentsOfURL:
	@abstract Initialise a trie witgh contents of a file.
	@discussion Attempts to create an NSArray with the contents of the file and then passes the array to <tt>-[NDTrie initWithArray:]</tt>.
	@param url A file url to a property list file generated from a <tt>NDTrie</tt> or <tt>NSArray</tt>
 */
- (id)initWithContentsOfURL:(NSURL *)url;
/*!
	@method initWithStrings:count:
	@abstract Initialise a trie with a c array.
	@discussion The order of th strings is ignored, duplicates will be ignored.
	@param strings A c array of <tt>NSString</tt>
	@param count The number of strings within the c array.
 */
- (id)initWithStrings:(NSString **)strings count:(NSUInteger)count;
/*!
	@method initWithObjects:forKeys:count:
	@abstract Initialize a trie with the contents of of a c array.
	@discussion Initializes a trie that includes a given number of objects and keys from a given C arrays.
	@param objects a c array of objects
	@param keys a c array of <tt>NSString</tt>s
	@param count The number of objects and keys
 */
- (id)initWithObjects:(id *)objects forKeys:(NSString **)keys count:(NSUInteger)count;
/*!
	@method initWithStrings:arguments:
	@abstract Initialise a trie with a <tt>va_list</tt> of <tt>NSString</tt>s
	@discussion This method is used by the varable number of string argument methods, The order of th strings is ignored, duplicates will be ignored.
	@param firstString The first string.
	@param arguments A va_list for the rest of the strings, the list needs to be nil terminated.
 */
- (id)initWithStrings:(NSString *)firstString arguments:(va_list)arguments;
/*!
	@method initWithObjectsAndKeys:arguments:
	@abstract Initialise a trie with a <tt>va_list</tt> of objects and keys
	@discussion This method is used by the varable number of object and keys arguments methods, The order of th strings is ignored, duplicates will be ignored.
	@param firstObject first object in a list of object and keys.
	@param arguments A va_list for the rest of the objects and keys, the list needs to be nil terminated.
 */
- (id)initWithObjectsAndKeys:(id)firstObject arguments:(va_list)arguments;

/*!
	@method initWithCaseInsensitive:
	@abstract Initialise a trie.
	@discussion The trie will be created empty.
	@param caseInsensitive Determines if key are handled in a case insensitive way or not.
 */
- (id)initWithCaseInsensitive:(BOOL)caseInsensitive;
/*!
	@method initWithWithCaseInsensitive:array:
	@abstract Initialise a trie with the contents of an <tt>NSArray</tt>.
	@discussion The trie will contain the strings contained within <tt><i>array</i></tt>, duplicates strings are allowed but only one will be added.
	@param array An array of strings, if an object within the array is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
 */
- (id)initWithCaseInsensitive:(BOOL)caseInsensitive array:(NSArray *)array;
/*!
	@method initWithCaseInsensitive:dictionary:
	@abstract Initialise a trie with the contents of an <tt>NSDictionary</tt>.
	@discussion The trie will contain the objects and keys contained within <tt><i>dictionary</i></tt>.
	@param dictionary An dictionary of objects and keys, if a key within the dictionary is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
 */
- (id)initWithCaseInsensitive:(BOOL)caseInsensitive dictionary:(NSDictionary *)dictionary;
/*!
	@method initWithCaseInsensitive:trie:
	@abstract Initialise a trie with the contents of another <tt>NDTrie</tt>.
	@discussion The trie will contain the strings contained within <tt><i>anotherTrie</i></tt>.
	@param array An array of strings.
 */
- (id)initWithCaseInsensitive:(BOOL)caseInsensitive trie:(NDTrie *)anotherTrie;
/*!
	@method initWithCaseInsensitive:strings:
	@abstract Initialise a trie with a list of <tt>NSString</tt>s
	@discussion The order of th strings is ignored, duplicates will be ignored.
	@param firstString The first string of a list of nil terminated strings, if an object within the list is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
 */
- (id)initWithCaseInsensitive:(BOOL)caseInsensitive strings:(NSString *)firstString, ... NS_REQUIRES_NIL_TERMINATION;
/*!
	@method initWithCaseInsensitive:objectsAndKeys:
	@abstract Initialise a trie with a list of objects and keys.
	@discussion The object and key pairs are added to the reciever, if a key within the list is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
	@param firstObject A list of objects and key paris.
 */
- (id)initWithCaseInsensitive:(BOOL)caseInsensitive objectsAndKeys:(id)firstObject , ... NS_REQUIRES_NIL_TERMINATION;
/*!
	@method initWithCaseInsensitive:contentsOfFile:
	@abstract Initialise a trie with contents of a file.
	@discussion Attempts to create an NSArray with the contents of the file and then passes the array to <tt>-[NDTrie initWithCaseInsensitive:array:]</tt>.
	@param path A path to a property list file generated from a <tt>NDTrie</tt> or <tt>NSArray</tt>
 */
- (id)initWithCaseInsensitive:(BOOL)caseInsensitive contentsOfFile:(NSString *)path;
/*!
	@method initWithCaseInsensitive:(BOOL)caseInsensitive contentsOfURL:
	@abstract Initialise a trie witgh contents of a file.
	@discussion Attempts to create an NSArray with the contents of the file and then passes the array to <tt>-[NDTrie initWithCaseInsensitive:array:]</tt>.
	@param url A file url to a property list file generated from a <tt>NDTrie</tt> or <tt>NSArray</tt>
 */
- (id)initWithCaseInsensitive:(BOOL)caseInsensitive contentsOfURL:(NSURL *)url;
/*!
	@method initWithCaseInsensitive:(BOOL)caseInsensitive strings:count:
	@abstract Initialise a trie with a c array.
	@discussion The order of th strings is ignored, duplicates will be ignored.
	@param strings A c array of <tt>NSString</tt>
	@param count The number of strings within the c array.
 */
- (id)initWithCaseInsensitive:(BOOL)caseInsensitive strings:(NSString **)strings count:(NSUInteger)count;
/*!
	@method initWithCaseInsensitive:(BOOL)caseInsensitive objects:forKeys:count:
	@abstract Initialize a trie with the contents of of a c array.
	@discussion Initializes a trie that includes a given number of objects and keys from a given C arrays.
	@param objects a c array of objects
	@param keys a c array of <tt>NSString</tt>s
	@param count The number of objects and keys
 */
- (id)initWithCaseInsensitive:(BOOL)caseInsensitive objects:(id *)objects forKeys:(NSString **)keys count:(NSUInteger)count;
/*!
	@method initWithCaseInsensitive:(BOOL)caseInsensitive strings:arguments:
	@abstract Initialise a trie with a <tt>va_list</tt> of <tt>NSString</tt>s
	@discussion This method is used by the varable number of string argument methods, The order of th strings is ignored, duplicates will be ignored.
	@param firstString The first string.
	@param arguments A va_list for the rest of the strings, the list needs to be nil terminated.
 */
- (id)initWithCaseInsensitive:(BOOL)caseInsensitive strings:(NSString *)firstString arguments:(va_list)arguments;
/*!
	@method initWithCaseInsensitive:(BOOL)caseInsensitive objectsAndKeys:arguments:
	@abstract Initialise a trie with a <tt>va_list</tt> of objects and keys
	@discussion This method is used by the varable number of object and keys arguments methods, The order of th strings is ignored, duplicates will be ignored.
	@param firstObject first object in a list of object and keys.
	@param arguments A va_list for the rest of the objects and keys, the list needs to be nil terminated.
 */
- (id)initWithCaseInsensitive:(BOOL)caseInsensitive objectsAndKeys:(id)firstObject arguments:(va_list)arguments;

/*!
	@method count
	@abstract get the number of strings with a trie.
	@discussion Returns the number of objects contained within th receiver.
 */
- (NSUInteger)count;

- (BOOL)isCaseInsensitive;

/*!
	@method containsObjectForKey:
	@abstract test if trie contains a string
	@discussion Test for the existence of a string with the recieve, for the string to be found it must be a complete string, for example if the trie contains the word "catalog" then a test for "cat" would not nessecarily return <tt>YES</tt>.
	@param string The string to test for.
	@result Returns <tt>YES</tt> if the recieve contains the string.
 */
- (BOOL)containsObjectForKey:(NSString *)string;
/*!
	@method containsObjectForKeyWithPrefix:
	@abstract Test if a trie contains any strings with a given prifix
	@discussion Test for the existence of any string with the recieve that has the prefix <tt><i>prefix</i><tt>, for example if the trie contains the word "catalog" then a test for "cat" would return <tt>YES</tt>.
	@param prefix The prefix to test for.
	@result Returns <tt>YES</tt> if the recieve contains at least one string with the prefix.
 */
- (BOOL)containsObjectForKeyWithPrefix:(NSString *)prefix;

/*!
	@method objectForKey:
	@abstract Find an object for a given key.
	@discussion If the method <tt>[NDMutableTrie addString:]</tt>was used then the object returned will be equivelent the the <tt><i>key</i></tt>.
	@param key The key to search for, unlike <tt>everyObjectForKeyWithPrefix:</tt> the key is a complete match.
	@result The found object or nil if no objects is found.
 */
- (id)objectForKey:(NSString *)key;
/*!
	@method everyObject
	@abstract return every string from a trie.
	@discussion <tt>everyObject</tt> returns every string within the recieve in an <tt>NSArray</tt> in an indeterminate order, if a string was added twice to the receiver the returned array will not contain two copies of the string.
 */
- (NSArray *)everyObject;
/*!
	@method everyObjectForKeyWithPrefix:
	@abstract Find every string with a given prefix.
	@discussion This method is what makes <tt>NDTrie</tt> so useful, it returns an <tt>NSArray</tt> with every string with the prefix <tt><i>prefix</i></tt>, if a string was added twice to the receiver the returned array will not contain two copies of the string.
	@param prefix The prefix to search for.
 */
- (NSArray *)everyObjectForKeyWithPrefix:(NSString *)prefix;

/*!
	@method getObjects:count:
	@abstract Get the objects in a c array.
	@discussion A buffer you create and is big enough to hold <tt><i>count</i></tt> items is filed with the objects in the reciever, if the c array is not big enough to hold all of the objects within the recieve then only <tt><i>count</i></tt> objects are returned which objects are returns in inderminate.
	@param buffer A c array to hold the returned objects.
	@param count The number of objects the c array <tt><i>buffer</i></tt> can hold.
 */
- (void)getObjects:(id *)buffer count:(NSUInteger)count;

/*!
	@method objectEnumerator
	@abstract Returns an enumerator object that lets you access each object in the receiver.
	@discussion Returns an enumerator object that lets you access each object in the receiver, in an indeterminate order.
	@result An enumerator object that lets you access each object in the receiver.
 */
- (NSEnumerator *)objectEnumerator;

/*!
	@method objectEnumeratorForKeyWithPrefix:
	@abstract Returns an enumerator object that lets you access each object in the receiver.
	@discussion Returns an enumerator object that lets you access each object in the receiver whose key has the prefix <tt><i>prefix</i></tt>, in an indeterminate order.
	@param prefix The prefix to search for.
	@result An enumerator object that lets you access each object in the receiver.
 */
- (NSEnumerator *)objectEnumeratorForKeyWithPrefix:(NSString *)prefix;

/*!
	@method isEqualToTrie:
	@abstract Compares two tries.
	@discussion The comparison between the two tries is performed by testing if every string within one trie has a equivelent string within the other trie, eqivelences is determined by comparing each unichar character within each string.
	@param otherTrie The trie to compare the reciever with.
	@result Returns <tt>YES</tt> if the tries are equal
 */
- (BOOL)isEqualToTrie:(NDTrie *)otherTrie;

/*!
	@method enumerateObjectsUsingFunction:
	@abstract Pass each members of a trie to a function.
	@discussion Each string is passed to the function <tt><i>func</i></tt>, the function can at any time stop the enumeration by returning <tt>NO</tt>. The enumeration occurs in an indeterminate order.
	@param func The function called for each string, it should be of the form <code>BOOL func(NSString * string)</code>
 */
- (void)enumerateObjectsUsingFunction:(BOOL (*)(NSString * ))func;
/*!
	@method enumerateObjectsForKeysWithPrefix:usingFunction:
	@abstract Pass each members of a trie with a given prefix to a function.
	@discussion Each string with the given prefix <tt><i>prefix</i></tt> is passed to the function <tt><i>func</i></tt>, the function can at any time stop the enumeration by returning <tt>NO</tt>. The enumeration occurs in an indeterminate order.
	@param prefix The prefix each string passed to the function begin with.
	@param func The function passed each string, the passed in strings will be the full string including the prefix, it should be of the form <code>BOOL func(NSString * string)</code>
 */
- (void)enumerateObjectsForKeysWithPrefix:(NSString*)prefix usingFunction:(BOOL (*)(id))func;
/*!
	@method enumerateObjectsUsingFunction:context:
	@abstract Pass each members of a trie to a function.
	@discussion Each string is passed to the function <tt><i>func</i></tt> along with the parameter <tt><i>context</i></tt>, the function can at any time stop the enumeration by returning <tt>NO</tt>. The enumeration occurs in an indeterminate order.
	@param func The function passed each string, it should be of the form <code>BOOL func(NSString * string, void * context)</code>
	@param context An addtional parameter to be assed to each function call
 */
- (void)enumerateObjectsUsingFunction:(BOOL (*)(id,void *))func context:(void*)context;
/*!
	@method enumerateObjectsForKeysWithPrefix:usingFunction:context:
	@abstract Pass each members of a trie with a given prefix to a function.
	@discussion Each string with the given prefix <tt><i>prefix</i></tt> is passed to the function <tt><i>func</i></tt> along with the parameter <tt><i>context</i></tt>, the function can at any time stop the enumeration by returning <tt>NO</tt>. The enumeration occurs in an indeterminate order.
	@param prefix The prefix each string passed to the function begin with.
	@param func The function passed each string, the passed in strings will be the full string including the prefix, it should be of the form <code>BOOL func(NSString * string, void * context)</code>
	@param context An addtional parameter to be assed to each function call
 */
- (void)enumerateObjectsForKeysWithPrefix:(NSString*)prefix usingFunction:(BOOL (*)(id,void *))func context:(void*)context;

/*!
	@method writeToFile:atomically:
	@abstract write a trie out to a file.
	@discussion The outputed file is a property list file that can be used to create an <tt>NSArray</tt> as well as a <tt>NDTrie</tt> 
	@param path The output file path
	@param atomically If YES, the trie is written to an auxiliary file, and then the auxiliary file is renamed to path. If NO, the trie is written directly to path. The YES option guarantees that path, if it exists at all, won’t be corrupted even if the system should crash during writing.
	@result Returns <tt>YES</tt> if Successful
 */
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomically;
/*!
	@method writeToURL:atomically:
	@abstract write a trie out to a file.
	@discussion The outputed file is a property list file that can be used to create an <tt>NSArray</tt> as well as a <tt>NDTrie</tt> 
	@param url The output file url
	@param atomically If YES, the trie is written to an auxiliary file, and then the auxiliary file is renamed to path. If NO, the trie is written directly to path. The YES option guarantees that path, if it exists at all, won’t be corrupted even if the system should crash during writing.
	@result Returns <tt>YES</tt> if Successful
 */
- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)atomically;

#if NS_BLOCKS_AVAILABLE
/*!
	@method enumerateObjectsUsingBlock:
	@abstract Pass each members of a trie to a block.
	@discussion Each string is passed to the block <tt><i>block</i></tt>, the block can at any time stop the enumeration by setting its parameter <tt><i>stop</i></tt> to <tt>YES</tt>. The enumeration occurs in an indeterminate order.
	@param block A block of the form <code>^(NSString * string, BOOL *stop)</code>
 */
- (void)enumerateObjectsUsingBlock:(void (^)(id object, BOOL *stop))block;
/*!
	@method enumerateObjectsForKeysWithPrefix:usingBlock:
	@abstract Pass each members of a trie with a given prefix to a block.
	@discussion Each string with the given prefix <tt><i>prefix</i></tt> is passed to the block <tt><i>block</i></tt>, the block can at any time stop the enumeration by setting its parameter <tt><i>stop</i></tt> to <tt>YES</tt>. The enumeration occurs in an indeterminate order.
	@param prefix The prefix each string passed to the block begin with.
	@param block A block of the form <code>^(NSString * string, BOOL *stop)</code>
 */
- (void)enumerateObjectsForKeysWithPrefix:(NSString*)prefix usingBlock:(void (^)(id object, BOOL *stop))block;

/*!
	@method everyObjectPassingTest:
	@abstract create an array with every string passing a test.
	@discussion Each string is pass to the block and if the block returns <tt>YES</tt> the string added to the array returned on enumeration completion, the block can at any time stop the enumeration by setting its parameter <tt><i>stop</i></tt> to <tt>YES</tt>. The enumeration occurs in an indeterminate order. If part of you test is to test the prefix of each string then you will get better performance by using <tt>-[NDTrie everyObjectForKeyWithPrefix:passingTest:]</tt>
	@param predicate Block used to test each string of the form <code>BOOL ^(NSString * string, BOOL *stop)</code>
	@result An <tt>NSArray</tt> containing every string that resulted in <tt><i>predicate</i><tt> returning true.
 */
- (NSArray *)everyObjectPassingTest:(BOOL (^)(id object, BOOL *stop))predicate;
/*!
	@method everyObjectForKeyWithPrefix:passingTest:
	@abstract create an array with every string beging with a prefix and passing a test.
	@discussion Each string with the prefix <tt><i>prefix</i></tt> is pass to the block and if the block returns <tt>YES</tt> the string added to the array returned on enumeration completion, the block can at any time stop the enumeration by setting its parameter <tt><i>stop</i></tt> to <tt>YES</tt>. The enumeration occurs in an indeterminate order.
	@param prefix The prefix each string passed to the block begin with.
	@param predicate Block used to test each string of the form <code>BOOL ^(NSString * string, BOOL *stop)</code>
	@result An <tt>NSArray</tt> containing every string that resulted in <tt><i>predicate</i><tt> returning true.
 */
- (NSArray *)everyObjectForKeyWithPrefix:(NSString*)prefix passingTest:(BOOL (^)(id object, BOOL *stop))predicate;

#endif

/*!
	@method objectForKeyedSubscript:
	@abstract Returns the value associated with a given key.
	@discussion This method is the same as valueForKey: and is to support Dictionary-Style subscripting.
	@param key The string key for which to return the corresponding value.
	@result The value associated with aKey, or nil if no value is associated with aKey.
 */
- (id)objectForKeyedSubscript:(NSString *)key;

@end

/*!
	@class NDMutableTrie 
	@superclass  NDTrie
	@abstract A mutable subclass of the <tt>NDtrie</tt>.
	@discussion \As <tt>NDTrie</tt> can be used as a replacement for <tt>NSSet</tt>, <tt>NDMutableTrie</tt> can be used as a replacment for <tt>NSMutableSet</tt> though it is very unlikly you will get as good performace, the current implementation of <tt>NDTrie</tt> stores it's contents in way that is not suited to adding and removing of elements, though this could change in the future.
 */
@interface NDMutableTrie : NDTrie

/*!
	@method addString:
	@abstract add a string the trie.
	@discussion This is eqivelent to calling setObject:forKey: with <tt><i>string</i></tt> as the key and object. The recieve may already contain an equivelent string, in which case no change to the trie will occur.
	@param object The String to add. which is used as the key and the object.
 */
- (void)addString:(NSString *)string;
/*!
	@method setObject:forKey:
	@abstract Add an object for a key.
	@discussion The recieve may already contain an equivelent key, in which case the object will be replaced.
	@param object The object to add for the given key.
	@param string A key with must a <tt>NSString</tt> or a subclass.
 */
- (void)setObject:(id)object forKey:(NSString *)string;
/*!
	@method addStrings:
	@abstract Add a list of strings to a trie.
	@discussion The order of the strings is of no consequence, duplicate strings are alowed but duplicates are not stored within the trie.
	@param firstString The first string of a list of nil terminated strings, if an object within the list is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
 */
- (void)addStrings:(NSString *)firstString, ... NS_REQUIRES_NIL_TERMINATION;
/*!
	@method setObjectsAndKeys:
	@abstract Add a set of key and objects to a trie.
	@discussion <tt>setObjectsAndKeys:</tt> set through every key object pair and adds it to the reciever, if a key is not a <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
	@param firstObject, The first object which must be followed by a key, the liist should be terminated by a <tt>nil</nil>, ifa key is <tt>nil</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
 */
- (void)setObjectsAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;
/*!
	@method addStrings:count:
	@abstract add a c array of strings to trie.
	@discussion The order of the strings is of no consequence, duplicate strings are alowed but duplicates are not stored within the trie.
	@param strings The c array of <tt>NSString</tt>s
	@param count the number of elements within <tt><i>strings</i></tt>
 */
- (void)addStrings:(NSString **)strings count:(NSUInteger)count;
/*!
	@method setObjects:forKeys:count:
	@abstract add a c array of objects and keys to a trie/
	@discussion Each object in the c array <tt><i>objects</i></tt> must have a key in the c array <tt><i>keys</i></tt>, there must be <tt><i>count</i></tt> or more objects and keys in each c array, if there are dupicate keys the only on object for the corresponding keys is used.
	@param objects A c array of objects
	@param keys A c array of keys, where each key belongs to the object with the same index in <tt><i>objects</i></tt>.
	@param count The number of objects and keys in the c arrays, there may be more but there can not be less.
 */
- (void)setObjects:(id *)objects forKeys:(NSString **)keys count:(NSUInteger)count;
/*!
	@method addTrie:
	@abstract add all strings from one trie to another.
	@discussion Ther may be strings common between the two trie, in which case the additional string will not be added.
 */
- (void)addTrie:(NDTrie *)trie;
/*!
	@method addArray:
	@abstract add an array of strings to a trie.
	@discussion The order of the strings is of no consequence, duplicate strings are alowed but duplicates are not stored within the trie.
	@param array An array of strings, if an object within the array is not an <tt>NSString</tt> then the exception <tt>NSInvalidArgumentException</tt> is thrown.
 */
- (void)addArray:(NSArray *)array;
/*!
	@method addDictionay:
	@abstract Add the contents of s dictionary to trie
	@discussion The is equivelent to enumerating over every key in the dictionary and calling [NDMutableTrie setObject:forKey:] for every object if a key is not a <tt>NSString</tt> then the exception <ttNSInvalidArgumentException</tt> is thrown/
	@param dictionary The dictionary for which each key/object pair is added to the reciever, every key must be if a <tt>NSString</tt> or subclass.
 */
- (void)addDictionay:(NSDictionary *)dictionary;

/*!
	@method removeObjectForKey:
	@abstract remove a string from a trie.
	@discussion Removes the string <tt><i>string</i></tt> from the receiver, any strings with a prefix equal to the string <tt><i>string</i></tt> are left within the trie.
	@param string The string to search for and remove.
 */
- (void)removeObjectForKey:(NSString *)string;
/*!
	@method removeAllObjects
	@abstract empty a trie of all strings.
	@discussion Equivelent to creating a new empty <tt>NDMutableTrie</tt>
 */
- (void)removeAllObjects;
/*!
	@method removeAllObjectsForKeysWithPrefix:
	@abstract remove all strings with a given prefix.
	@discussion Every string with the prefix <tt><i>prefix</i></tt> is removed from the recieve including any string that is equal to the prefix.
	@param prefix The prefix of all string removed from the recieve.
 */
- (void)removeAllObjectsForKeysWithPrefix:(NSString *)prefix;

- (void)setObject:(id)object forKeyedSubscript:(NSString *)aKey;

@end
