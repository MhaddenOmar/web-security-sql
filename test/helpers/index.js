let fs = require('fs');
let path = require('path');
let {Client} = require('pg');

let client;

exports.Helpers = class{


    constructor(){
        console.log("we heree");        
        let builder = require('../../lib/builder');        
        this.sql = builder.readSql();
        // fs.writeFileSync('./build/1-0-0.sql',this.sql);
        
    }

    connect(){
        client = {"user": "postgres","host": "127.0.0.1","database": "thingy","postgres": "postgres","port": 5432}
        
        if(process.env.NODE_ENV === 'test'){        
        dbConfig = require("../../test.db.config.json");
        }   
        client.connect();
    }
    
    initDb(next){        
        client.query(this.sql, function(err, result){        
        if(err){
            next(err,null);
        }else{
            next(null,result);
        }

    })};

    getClient(){        
        return client;
    }
}