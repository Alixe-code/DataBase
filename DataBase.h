//
//  DataBase.h
//  
//
//  Created by 刘 俊 on 12-11-19.
//
//

//部分实现从直接操作数据库改用第三方类FMDataBase -LJ 2013-09-24

#import <Foundation/Foundation.h>
#import "sqlite3.h"
#import "FMDatabase.h"

@interface DataBase : NSObject
{
    NSString *dataBasePath;
}

//建表
-(void)creatTable:(NSArray *)numericFields withTableName:(NSString *)tableName;
-(void)creatTable:(NSArray *)numericFields withTableName:(NSString *)tableName withError:(NSError **)error;

//查询
-(NSArray *)queryTable:(NSArray *)fields withTable:(NSString *)tableName withCondition:(NSArray *)conditions;
//复杂查询(在外部编写sql语句)
-(NSArray *)queryData:(NSArray *)fields withSql:(NSString *)sqlString;
//删除数据
-(void)deleteData:(NSString *)sqlString;
-(void)deleteData:(NSString *)sqlString withError:(NSError **)error;
//更新数据
-(void)updateData:(NSString *)sqlString;
//根据字段和表名写数据
-(void)writeItemToDatabase:(NSArray *)values withSql:(NSString *)sqlString;
-(void)writeItemToDatabase:(NSArray *)values withSql:(NSString *)sqlString withError:(NSError **)error;
//表是否存在(用于判断是否是第一次加载)
-(BOOL)tableExited:(NSString *)tableName;


@end
