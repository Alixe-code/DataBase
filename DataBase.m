//
//  DataBase.m
//
//
//  Created by 刘 俊 on 12-11-19.
//
//  GitHub : vividloves@gmail.com

#define SQLITE_NAME         @"DataBase.sqlite"

#define START_TRANSACTION() sqlite3_exec(database, "begin transaction;", NULL, NULL, NULL)
#define END_TRANSACTION()   sqlite3_exec(database, "commit transaction;", NULL, NULL, NULL)

#define debugLog(...) NSLog(__VA_ARGS__)

#define ERROR_DOMAIN @"LJ_DataBase"

#import "DataBase.h"

@implementation DataBase

- (void)errorWithDiscriprion:(NSString *)description code:(int)errCode error:(NSError **)anError
{
    if (description==nil||[description length]==0)
    {
        return ;
    }
    
    // Create the underlying error.
    NSError *underlyingError = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain
                                                          code:errno userInfo:nil];
    // Create and return the custom domain error.
    NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey : description,
                                       NSUnderlyingErrorKey : underlyingError};
    
    *anError = [[NSError alloc] initWithDomain:ERROR_DOMAIN
                                          code:errCode userInfo:errorDictionary];
}

-(id)init
{
    if (self==[super init])
    {
        NSString * doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        dataBasePath = [doc stringByAppendingPathComponent:SQLITE_NAME];
    }
    return self;
}

//创建一张表
-(void)creatTable:(NSArray *)numericFields withTableName:(NSString *)tableName
{
    //拼SQL语句
    if (numericFields==nil||[numericFields count]==0||tableName==nil)
    {
        return;
    }
    
    NSMutableString *sqlString=[[NSMutableString alloc]init];
    [sqlString appendString:[NSString stringWithFormat:@"create table if not exists %@  (id integer primary key autoincrement,",tableName]];
    
    for (NSString *string in numericFields)
    {
        NSString *field=[NSString stringWithFormat:@"%@ text,",string];
        [sqlString appendString:field];
    }
    //将末尾的逗号替换为括号
    NSRange endRange=NSMakeRange([sqlString length]-1, 1);
    [sqlString replaceCharactersInRange:endRange withString:@")"];
    
    // create it
    FMDatabase * db = [FMDatabase databaseWithPath:dataBasePath];
    if ([db open])
    {
        BOOL res = [db executeUpdate:sqlString];
        if (!res)
        {
            debugLog(@"error when creating db table");
        }
        else
        {
            //debugLog(@"succ to creating db table");
        }
        [db close];
    }
    else
    {
        debugLog(@"error when open db");
    }
}

//创建一张表
-(void)creatTable:(NSArray *)numericFields withTableName:(NSString *)tableName withError:(NSError **)error
{
    //拼SQL语句
    if (numericFields==nil||[numericFields count]==0||tableName==nil)
    {
        return;
    }
    
    NSMutableString *sqlString=[[NSMutableString alloc]init];
    [sqlString appendString:[NSString stringWithFormat:@"create table if not exists %@  (id integer primary key autoincrement,",tableName]];
    
    for (NSString *string in numericFields)
    {
        NSString *field=[NSString stringWithFormat:@"%@ text,",string];
        [sqlString appendString:field];
    }
    //将末尾的逗号替换为括号
    NSRange endRange=NSMakeRange([sqlString length]-1, 1);
    [sqlString replaceCharactersInRange:endRange withString:@")"];
    
    // create it
    NSString *errorStr;
    FMDatabase * db = [FMDatabase databaseWithPath:dataBasePath];
    if ([db open])
    {
        BOOL res = [db executeUpdate:sqlString];
        if (!res)
        {
            errorStr=@"error when creating db table";
        }
        else
        {
            //debugLog(@"succ to creating db table");
        }
        [db close];
    }
    else
    {
        errorStr = @"error when open db";
    }
    
    [self errorWithDiscriprion:errorStr code:0 error:error];
}

//表是否存在(用于判断是否是第一次加载)
-(BOOL)tableExited:(NSString *)tableName
{
    FMDatabase * db = [FMDatabase databaseWithPath:dataBasePath];
    if ([db open])
    {
        tableName = [tableName lowercaseString];
        
        FMResultSet *rs = [db executeQuery:@"select [sql] from sqlite_master where [type] = 'table' and lower(name) = ?", tableName];
        
        //if at least one next exists, table exists
        BOOL returnBool = [rs next];
        
        //close and free object
        [rs close];
        
        return returnBool;
    }
    else
    {
        debugLog(@"error when open db");
    }
    
    return NO;
}

- (NSArray *)queryTable:(NSArray *)fields withTable:(NSString *)tableName withCondition:(NSArray *)conditions
{
    NSMutableArray *valueArray=[[NSMutableArray alloc]init];
    NSMutableString *sqlString=[[NSMutableString alloc]initWithString:@"select "];
    
    for (NSString *string in fields)
    {
        NSString *field=[NSString stringWithFormat:@"%@,",string];
        [sqlString appendString:field];
    }
    //将末尾的逗号替换为空格
    NSRange endRange=NSMakeRange([sqlString length]-1, 1);
    [sqlString replaceCharactersInRange:endRange withString:@" "];
    //增加表名
    [sqlString appendString:[NSString stringWithFormat:@"from %@",tableName]];
    
    //增加查询时间，查询条件为空则返回全部
    if (conditions)
    {
        [sqlString appendString:@" WHERE "];
        
        for (NSString *condition in conditions)
        {
            [sqlString appendString:[NSString stringWithFormat:@"%@ and ",condition]];
        }
        //将末尾的空格和and去掉
        NSRange endRange=NSMakeRange([sqlString length]-5, 5);
        [sqlString replaceCharactersInRange:endRange withString:@""];
    }
    //NSLog(@"%@",sqlString);

    FMDatabase * db = [FMDatabase databaseWithPath:dataBasePath];
    if ([db open])
    {
        FMResultSet * rs = [db executeQuery:sqlString];
        while ([rs next])
        {
            NSMutableDictionary *dic=[[NSMutableDictionary alloc]init];
            for (int i=0; i<[fields count]; i++)
            {
                NSString * value = [rs stringForColumn:[fields objectAtIndex:i]];
                
                if (value!=nil && [value length]!=0)
                {
                    [dic setObject:value forKey:[fields objectAtIndex:i]];
                }
                else
                {
                    //[dic setObject:@" " forKey:[fields objectAtIndex:i]];
                }
            }
            
            //将单条记录写入数组
            if ([dic count]!=0)
            {
                [valueArray addObject:dic];
            }
        }
        [db close];
    }
    
    //返回数据
    return valueArray;
}

//复杂查询(在外部编写sql语句)
-(NSArray *)queryData:(NSArray *)fields withSql:(NSString *)sqlString
{
    NSMutableArray *valueArray=[[NSMutableArray alloc]init];
    
    FMDatabase * db = [FMDatabase databaseWithPath:dataBasePath];
    if ([db open])
    {
        FMResultSet * rs = [db executeQuery:sqlString];
        while ([rs next])
        {
            NSMutableDictionary *dic=[[NSMutableDictionary alloc]init];
            for (int i=0; i<[fields count]; i++)
            {
                NSString * value = [rs stringForColumn:[fields objectAtIndex:i]];
                
                if (value!=nil && [value length]!=0)
                {
                    [dic setObject:value forKey:[fields objectAtIndex:i]];
                }
                else
                {
                    //[dic setObject:@"未知" forKey:[fields objectAtIndex:i]];
                }
            }
            
            //将单条记录写入数组
            if ([dic count]!=0)
            {
                [valueArray addObject:dic];
            }
        }
        [db close];
    }
    
    //返回数据
    return valueArray;
}

//删除
- (void)deleteData:(NSString *)sqlString
{
    FMDatabase * db = [FMDatabase databaseWithPath:dataBasePath];
    if ([db open])
    {
        BOOL res = [db executeUpdate:sqlString];
        if (!res)
        {
            debugLog(@"error to delete db data");
        }
        else
        {
            //debugLog(@"succ to deleta db data");
        }
        [db close];
    }
}

- (void)deleteData:(NSString *)sqlString withError:(NSError **)error
{
    NSString *errStr;
    FMDatabase * db = [FMDatabase databaseWithPath:dataBasePath];
    if ([db open])
    {
        BOOL res = [db executeUpdate:sqlString];
        if (!res)
        {
            errStr=@"error to delete db data";
        }
        else
        {
            //debugLog(@"succ to deleta db data");
        }
        [db close];
    }
    else
    {
        errStr = @"error when open db";
    }
    
    [self errorWithDiscriprion:errStr code:0 error:error];
}

//根据字段和表名写数据
-(void)writeItemToDatabase:(NSArray *)values withSql:(NSString *)sqlString
{
    FMDatabase * db = [FMDatabase databaseWithPath:dataBasePath];
    if ([db open])
    {
        BOOL res = [db executeUpdate:sqlString withArgumentsInArray:values];
        if (!res)
        {
            debugLog(@"error to insert data");
        }
        else
        {
            //debugLog(@"succ to insert data");
        }
        [db close];
    }
}

-(void)writeItemToDatabase:(NSArray *)values withSql:(NSString *)sqlString withError:(NSError **)error
{
    NSString *errStr;
    FMDatabase * db = [FMDatabase databaseWithPath:dataBasePath];
    if ([db open])
    {
        BOOL res = [db executeUpdate:sqlString withArgumentsInArray:values];
        if (!res)
        {
            errStr = @"error to insert data";
        }
        else
        {
            //debugLog(@"succ to insert data");
        }
        [db close];
    }
    else
    {
        errStr = @"error when open db";
    }
    
    [self errorWithDiscriprion:errStr code:0 error:error];
}

-(void)updateData:(NSString *)sqlString
{
    FMDatabase * db = [FMDatabase databaseWithPath:dataBasePath];
    if ([db open])
    {
        BOOL res = [db executeUpdate:sqlString];
        if (!res)
        {
            debugLog(@"error to updata data");
        }
        else
        {
            //debugLog(@"succ to updata data");
        }
        [db close];
    }
}

@end
