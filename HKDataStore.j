//  Copyright (c) 2011 HoboCode
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//


@implementation _CPConcreteMutableSet (HKSetRehash)

- (void)rehash
{
    var newcontents = {};
    var key = nil;
    var object = nil;

    for ( key in _contents )
    {
        object = _contents[key];

        newcontents[[object UID]] = object;
    }

    _contents = newcontents;
}

@end


//
//  Singleton instance
//
var gHKDataStore = nil;

//
//  Class implementation
//
@implementation HKDataStore : CPObject
{
    CPString                protocol @accessors;     // e.g. http://
    CPString                host @accessors;         // e.g. www.example.com
    CPString                basePath @accessors;     // e.g. api/v1
    CPString                baseKey @accessors;      // base key where objects is stored in returned JSON object from API

    CPDictionary            additionalHTTPHeaders @accessors;

    CPDictionary            types;
    CPDictionary            objects;
    CPDictionary            controllers;
    CPDictionary            observers;
    CPDictionary            dependencies;
    CPSet                   loaded;
    CPArray                 operations;
    HKDataStoreOperation    current;
    HKURLRequestQueue       queue;
    var                     idle;
}

//
//  Singleton accessor
//
+ (HKDataStore)sharedDataStore
{
    if ( gHKDataStore == nil )
    {
        gHKDataStore = [[HKDataStore alloc] init];
    }

    return gHKDataStore;
}

//
//  Init
//
- (id)init
{
    if ( self = [super init] )
    {
        types = [[CPDictionary alloc] init];
        objects = [[CPDictionary alloc] init];
        controllers = [[CPDictionary alloc] init];
        observers = [[CPDictionary alloc] init];
        dependencies = [[CPDictionary alloc] init];
        loaded = [[CPSet alloc] init];
        operations = [[CPArray alloc] init];
        queue = [[HKURLRequestQueue alloc] init];
        idle = true;
    }

    return self;
}

- (CPString)baseURL
{
    return [self protocol] + [self host] + "/" + [self basePath] + "/";
}

- (void)addObserver:(id)observer selector:(SEL)sel forDataObjectNames:(CPArray)objectNames
{
    for ( var i = 0; i < objectNames.length; i++ )
    {
        var objectName = objectNames[i];
        var o = [observers objectForKey:objectName];

        if ( o == nil )
        {
            o = [CPArray array];
            [observers setObject:o forKey:objectName];
        }

        o.push([observer, sel]);
    }
}

- (void)removeObserver:(id)observer
{
    var objectName;
    for ( objectName in observers )
    {
        [self removeObserver:observer forObjectName:objectName];
    }
}

- (void)removeObserver:(id)observer forObjectName:(CPString)objectName
{
    var observerArray = [observers objectForKey:objectName];

    if ( observerArray == nil ) return;

    for ( var i = 0; i < observerArray.length; i++ )
    {
        var o = observerArray[i];
        if ( o[0] == observer )
        {
            [observerArray removeObject:o];
        }
    }
}

- (void)removeAllObservers
{
    [observers removeAllObjects];
}

- (void)callObserversWithObjectName:(CPString)objectName operation:(int)operation
{
    if ( [observers objectForKey:objectName] != nil)
    {
        var observer,
            enumerator,
            invocation;

        invocation = [CPInvocation invocationWithMethodSignature:nil];
        [invocation setArgument:self atIndex:2];
        [invocation setArgument:objectName atIndex:3];
        [invocation setArgument:operation atIndex:4];

        enumerator = [[observers objectForKey:objectName] objectEnumerator];
        while ( (observer = [enumerator nextObject]) != nil )
        {
            [invocation setSelector:observer[1]];
            [invocation invokeWithTarget:observer[0]];
        }
    }
}


- (void)addObserver:(id)observer selector:(SEL)sel forDataObjectName:(CPString)objectName
{
    [self addObserver:observer selector:sel forDataObjectNames:[objectName]];
}

- (void)registerDataObjectClass:(Class)objectClass forDataObjectName:(CPString)objectName
{
    [self registerDataObjectClass:objectClass forDataObjectName:objectName withDependencies:nil];
}

- (void)registerDataObjectClass:(Class)objectClass forDataObjectName:(CPString)objectName withDependencies:(CPSet)objectDependencies
{
    if ( [objectClass isSubclassOfClass:[HKDataObject class]] )
    {
        [types setObject:objectClass forKey:objectName];
        [objects setObject:[CPSet set] forKey:objectName];

        if ( objectDependencies != nil )
        {
            CPLog.debug( "HKDataStore::registerDataObjectClass->Objects (" + objectName + ") are dependent on: " + objectDependencies );

            [dependencies setObject:objectDependencies forKey:objectName];

            if ( ![loaded containsObject:objectName] && [objectDependencies isSubsetOfSet:loaded] )
            {
                CPLog.debug( "HKDataStore::registerDataObjectClass->Object dependencies (" + objectName + ") are all loaded, load immediately!" );

                [loaded addObject:objectName];
                [operations addObject:[HKDataStoreOperation operationWithType:HKDataStoreOperationGET object:objectClass]];
            }
        }
        else
        {
            [loaded addObject:objectName];
            [operations addObject:[HKDataStoreOperation operationWithType:HKDataStoreOperationGET object:objectClass]];
        }

        var keys = [dependencies allKeys];
        var key;
        var dependent;
        var enumerator = [keys objectEnumerator];

        while ( (key = [enumerator nextObject]) != nil )
        {
            dependent = [dependencies objectForKey:key];

            if ( ![loaded containsObject:key] && [dependent isSubsetOfSet:loaded] )
            {
                CPLog.debug( "HKDataStore::registerDataObjectClass->Loading objects (" + key + ") cause all dependencies are now loaded" );

                [loaded addObject:key];
                [operations addObject:[HKDataStoreOperation operationWithType:HKDataStoreOperationGET object:[types objectForKey:key]]];

                enumerator = [keys objectEnumerator];
            }
        }

        [self performNextOperation];
    }
}

- (void)registerArrayController:(CPArrayController)arrayController forDataObjectName:(CPString)objectName
{
    var set = [controllers objectForKey:objectName];

    if ( set == nil )
    {
        set = [[CPSet alloc] init];

        [controllers setObject:set forKey:objectName];
    }

    [set addObject:arrayController];

    [self updateControllersForDataObjectName:objectName];
}

- (void)unregisterArrayController:(CPArrayController)arrayController forDataObjectName:(CPString)objectName
{
    var set = [controllers objectForKey:objectName];

    if ( set != nil )
    {
        [set removeObject:arrayController];
    }
}


- (void)refreshForDataObjectName:(CPString)objectName
{
    var oclass = [types objectForKey:objectName];

    if ( oclass != nil )
    {
        [operations addObject:[HKDataStoreOperation operationWithType:HKDataStoreOperationGET object:oclass]];

        [self performNextOperation];
    }
}

- (void)resetForDataObjectName:(CPString)objectName
{
    var objs = [objects objectForKey:objectName];
    
    [objs removeAllObjects];
    
    [self refreshForDataObjectName:objectName];
}

- (HKDataObject)newDataObjectForName:(CPString)objectName
{
    return [self newDataObjectForName:objectName initialValues:nil];
}

- (HKDataObject)newDataObjectForName:(CPString)objectName initialValues:(CPDictionary)values
{
    var oclass = [types objectForKey:objectName];
    
    if ( [oclass readOnly] )
    {
        CPLog.debug( "HKDataStore::newDataObjectForName->Error: 'Can't create new instances of a read-only data object class'");
        return;
    }

    var retval = nil;
    var enumerator = nil;
    var attribute = nil;
    var set = nil;
    var request = nil;

    if ( oclass != nil )
    {
        retval = [[oclass alloc] init];
                        
        if ( values != nil )
        {
            var key = nil,
                value = nil;

            enumerator = [values keyEnumerator];

            while ( (key = [enumerator nextObject]) != nil )
            {
                value = [values objectForKey:key];

                if ( value != nil )
                {
                    [retval setValue:value forKey:key];
                }
            }
        }

        enumerator = [[oclass attributesToObserve] objectEnumerator];

        while ( (attribute = [enumerator nextObject]) != nil )
        {
            [retval addObserver:self forKeyPath:attribute options:0 context:nil];
        }

        set = [objects objectForKey:objectName]; [set addObject:retval];

        CPLog.debug( "HKDataStore::ADD->Object (" + [retval description] + ")");
        CPLog.debug( "HKDataStore::AFTER_ADD->Objects (" + objectName + "): " + set);

        if ( [retval sync] )
        {
            [operations addObject:[HKDataStoreOperation operationWithType:HKDataStoreOperationPOST object:retval]];

            [self performNextOperation];
        }
    }
    
    return retval;
}

- (void)deleteDataObject:(HKDataObject)object
{
    var keys = [types allKeysForObject:[object class]]

    if ( [keys count] > 0 )
    {
        var key = [keys objectAtIndex:0];
        var set = [objects objectForKey:key];
        
        [set removeObject:object];

        CPLog.debug( "HKDataStore::DELETE->Object (" + object + ")");
        CPLog.debug( "HKDataStore::AFTER_DELETE->Objects (" + key + "): " + set);

        [operations addObject:[HKDataStoreOperation operationWithType:HKDataStoreOperationDELETE object:object]];

        [self performNextOperation];
    }
}

- (void)dataObjectWithId:(int)oid forName:(CPString)objectName
{
    var set = [objects objectForKey:objectName],
        ret = nil;

    if ( set != nil )
    {
        var enumerator = [set objectEnumerator];

        while ( (object = [enumerator nextObject]) != nil )
        {
            if ( [object oid] == oid )
            {
                ret = object;
                break;
            }
        }
    }

    return ret;
}

- (CPSet)dataObjectsForName:(CPString)objectName
{
    return [objects objectForKey:objectName];
}

- (CPSet)dataObjectsForName:(CPString)objectName matchingPredicate:(CPPredicate)objectPredicate
{
    var set = [objects objectForKey:objectName];
    var array = [set allObjects];

    return [CPSet setWithArray:[array filteredArrayUsingPredicate:objectPredicate]];
}

//
//  Internal
//

- (void)queueOperation:(HKDataStoreOperation)operation
{
    [operations addObject:operation];

    [self performNextOperation];
}

//
//  Private
//

- (void)performNextOperation
{
    CPLog.debug( "HKDataStore::performNextOperation (idle='" + idle + "', operations='" + [operations count] + "')");
    
    current = nil;
    
    if ( [operations count] == 0 )
        return;

    if ( !idle )
        return;

    idle = false;

    current = [operations objectAtIndex:0]; [operations removeObjectAtIndex:0];

    switch ( [current type] )
    {
        case HKDataStoreOperationGET:
            [queue performRequest:[self URLRequestForGETOperationForDataObjectClass:[current object]]];
            break;

        case HKDataStoreOperationPOST:
            [queue performRequest:[self URLRequestForPOSTOperationForDataObject:[current object]]];
            break;

        case HKDataStoreOperationPUT:
            [queue performRequest:[self URLRequestForPUTOperationForDataObject:[current object]]];
            break;

        case HKDataStoreOperationDELETE:
            [queue performRequest:[self URLRequestForDELETEOperationForDataObject:[current object]]];
            break;
            
        case HKDataStoreOperationFUNCTION:
             [queue performRequest:[self URLRequestForFUNCTIONOperationForDataObject:[current object] parameters:[current parameters]]];
             break;
    }
}

- (BOOL)hasQueuedOperationOfType:(int)type object:(HKDataObject)object
{
    var retval = NO;
    var enumerator = [operations objectEnumerator];
    var operation = nil;
    
    while ( (operation = [enumerator nextObject]) != nil )
    {
        if ( [operation type] == type && [operation object] == object )
            return YES;
    }
    
    return NO;
}

- (void)updateControllersForDataObjectName:(CPString)objectName
{
    var objs = [objects objectForKey:objectName];

    if ( objs != nil )
    {
        var set = [controllers objectForKey:objectName];

        if ( set != nil )
        {
            var enumerator = [set objectEnumerator];
            var controller = nil;

            while ( (controller = [enumerator nextObject]) != nil )
            {
                CPLog.debug("HKDataStore-> changing content to: " + controller );

                var predicate = [controller filterPredicate];
                [controller setContent:[objs allObjects]];
                if ( predicate )
                {
                    [controller setFilterPredicate:predicate];
                }
            }
        }
    }
}

//
//  URL handling
//

- (HKURLRequest)URLRequestForGETOperationForDataObjectClass:(Class)objectClass
{
    var base = [self baseURL];
    var url = base + [objectClass baseURL];
    var request = nil;

    request = [HKURLRequest requestWithURL:url target:self selector:@selector(GETOperationDidComplete:) context:objectClass];
    [request setHTTPMethod:@"GET"];

    [self addAdditionalHTTPHeadersToRequest:request];

    return request;
}

- (HKURLRequest)URLRequestForPOSTOperationForDataObject:(HKDataObject)object
{
    var base = [self baseURL];
    var url = base + [[object class] baseURL];
    var request = nil;
    var parameters = nil;
    var attribute = nil;
    var value = nil;
    var enumerator = [[[object class] attributesToObserve] objectEnumerator];
    var readonly = [[object class] attributesReadOnly];

    while ( (attribute = [enumerator nextObject]) != nil )
    {
        if ( attribute == @"sync" || [readonly containsObject:attribute] )
            continue;

        value = [object valueForKey:attribute];

        if ( value != nil )
        {
            if ( parameters == nil )
            {
                parameters = [[CPDictionary alloc] init];
            }

            [parameters setObject:value forKey:[attribute underscoreString]];
        }
    }

    request = [HKURLRequest requestWithURL:url target:self selector:@selector(POSTOperationDidComplete:) context:object];

    [request setHTTPMethod:@"POST"];

    if ( parameters != nil )
    {
        [request setParameters:parameters];
    }

    [self addAdditionalHTTPHeadersToRequest:request];

    return request;
}

- (HKURLRequest)URLRequestForPUTOperationForDataObject:(HKDataObject)object
{
    var base = [self baseURL];
    var url = base + [object instanceURL];
    var request = nil;
    var parameters = nil;
    var attribute = nil;
    var value = nil;
    var enumerator = [[[object class] attributesToObserve] objectEnumerator];
    var readonly = [[object class] attributesReadOnly];

    while ( (attribute = [enumerator nextObject]) != nil )
    {
        if ( attribute == @"sync" || [readonly containsObject:attribute]  )
            continue;

        value = [object valueForKey:attribute];

        if ( value != nil )
        {
            if ( parameters == nil )
            {
                parameters = [[CPDictionary alloc] init];
            }

            [parameters setObject:value forKey:attribute];
        }
    }

    request = [HKURLRequest requestWithURL:url target:self selector:@selector(PUTOperationDidComplete:) context:object];

    [request setHTTPMethod:@"PUT"];

    if ( parameters != nil )
    {
        [request setParameters:parameters];
    }

    [self addAdditionalHTTPHeadersToRequest:request];

    return request;
}

- (HKURLRequest)URLRequestForDELETEOperationForDataObject:(HKDataObject)object
{
    var base = [self baseURL];
    var url = base + [object instanceURL];
    var request = nil;

    request = [HKURLRequest requestWithURL:url target:self selector:@selector(DELETEOperationDidComplete:) context:object];
    [request setHTTPMethod:@"DELETE"];

    [self addAdditionalHTTPHeadersToRequest:request];

    return request;
}

- (HKURLRequest)URLRequestForFUNCTIONOperationForDataObject:(HKDataObject)object parameters:(CPArray)parameters
{
    var base = [self baseURL];
    var url = base + [object instanceURL] + "/" + [parameters componentsJoinedByString:@"/"];
    var request = nil;

    request = [HKURLRequest requestWithURL:url target:self selector:@selector(FUNCTIONOperationDidComplete:) context:object];
    [request setHTTPMethod:@"GET"];

    [self addAdditionalHTTPHeadersToRequest:request];

    return request;
}

- (void)addAdditionalHTTPHeadersToRequest:(HKURLRequest)request
{
    if ( [self additionalHTTPHeaders] )
    {
        var headers = [self additionalHTTPHeaders],
            enumerator = [headers keyEnumerator],
            field = nil,
            val = nil;

        while ( field = [enumerator nextObject] )
        {
            val = [headers objectForKey:field];
            [request setValue:val forHTTPHeaderField:field];
        }
    }
}

//
//  Callbacks
//

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    if ( [[object class] readOnly] )
    {
        return;
    }
    
    if ( ![object sync] )
    {
        CPLog.debug( "HKDataStore::CHANGE->Object (" + object + ") sync flag off");
        return;
    }
    
    CPLog.debug( "HKDataStore::CHANGE->Object (" + object + ") SET '" + keyPath + "' TO '" + object[keyPath] + "'");
    
    if ( [self hasQueuedOperationOfType:HKDataStoreOperationPUT object:object] )
        return;
        
    if ( [self hasQueuedOperationOfType:HKDataStoreOperationPOST object:object] )
        return;
    
    if ( [object oid] == -1 )
    {
        [operations addObject:[HKDataStoreOperation operationWithType:HKDataStoreOperationPOST object:object]];
    }
    else
    {
        [operations addObject:[HKDataStoreOperation operationWithType:HKDataStoreOperationPUT object:object]];
    }
    
    [self performNextOperation];
}


//
//  Request Callbacks
//

- (void)GETOperationDidComplete:(HKURLResult)result
{
    if ( [result success] )
    {
        var context = [result context];
        var keys = [types allKeysForObject:context]

        if ( [keys count] > 0 )
        {
            var key = [keys objectAtIndex:0];
            var set = [objects objectForKey:key];
            var newobjects = [CPSet set];
            var enumerator = nil;
            var aenumerator = nil;
            var json = nil;
            var instance = nil;
            var attribute = nil;

            if ( [self baseKey] != nil )
            {
                var o = [result object]; // expect that [result object] is a JS object
                enumerator = [o[[self baseKey]] objectEnumerator];
            }
            else
            {
                enumerator = [[result object] objectEnumerator];
            }

            CPLog.debug( "HKDataStore::AFTER_GET->Objects BEFORE INSERT (" + key + "): " + set);

            [set rehash];

            while ( (json = [enumerator nextObject]) != nil )
            {
                instance = [[context alloc] init];

                [instance setupFromJSON:json];
                [newobjects addObject:instance];

                aenumerator = [[context attributesToObserve] objectEnumerator];
                
                while ( (attribute = [aenumerator nextObject]) != nil )
                {
                    [instance addObserver:self forKeyPath:attribute options:0 context:nil];
                }
            }

            [set unionSet:newobjects];
            [set intersectSet:newobjects];

            // set now contains all objects from the json fetch

            [self updateControllersForDataObjectName:key];

            CPLog.debug( "HKDataStore::AFTER_GET->Objects AFTER INSERT (" + key + "): " + set);

            [self callObserversWithObjectName:key operation:HKDataStoreOperationGET];
        }
    }

    idle = true; [self performNextOperation];
}

- (void)POSTOperationDidComplete:(HKURLResult)result
{
    if ( [result success] )
    {
        var context = [result context];
        var object = [result object];
        var keys = [types allKeysForObject:[context class]]

        [context setupFromJSON:object];

        if ( [keys count] > 0 )
        {
            var key = [keys objectAtIndex:0];
            var set = [objects objectForKey:key];
            
            [set rehash];
            
            [self updateControllersForDataObjectName:key];

            [self callObserversWithObjectName:key operation:HKDataStoreOperationPOST];
        }
    }

    idle = true; [self performNextOperation];
}

- (void)PUTOperationDidComplete:(HKURLResult)result
{
    if ( [result success] )
    {
        var context = [result context];
        var keys = [types allKeysForObject:[context class]]

        if ( [keys count] > 0 )
        {
            var key = [keys objectAtIndex:0];

            [self updateControllersForDataObjectName:key];

            [self callObserversWithObjectName:key operation:HKDataStoreOperationPUT];
        }
    }

    idle = true; [self performNextOperation];
}

- (void)DELETEOperationDidComplete:(HKURLResult)result
{
    if ( [result success] )
    {
        var context = [result context];
        var keys = [types allKeysForObject:[context class]]

        if ( [keys count] > 0 )
        {
            var key = [keys objectAtIndex:0];

            [self updateControllersForDataObjectName:key];

            [self callObserversWithObjectName:key operation:HKDataStoreOperationDELETE];
        }
    }

    idle = true; [self performNextOperation];
}

- (void)FUNCTIONOperationDidComplete:(HKURLResult)result
{
    if ( [result success] )
    {
        var context = [result context];
        var object = [result object];
        var keys = [types allKeysForObject:[context class]]

        [context setupFromJSON:object];

        if ( [keys count] > 0 )
        {
            var key = [keys objectAtIndex:0];

            [self updateControllersForDataObjectName:key];

            [self callObserversWithObjectName:key operation:HKDataStoreOperationFUNCTION];
        }
    }

    idle = true; [self performNextOperation];
}

@end