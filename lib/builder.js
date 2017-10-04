const fs = require('fs');
const path = require('path');
const config = require('../package.json');
const pg = require('pg');

const versionRoot = config.version.replace(/\./g, "-");
const sourceDir = path.join(__dirname + "./../sql/" ,versionRoot);

const loadFiles = function(){
    const glob = require('glob');
    const globPattern = path.join(sourceDir, "**/*.sql")

    const files = glob.sync(globPattern, {nosort: true});
    let result = ['set search_path=membership;'];    

    files.forEach(file=>{
        const sql = fs.readFileSync(file,{encoding: 'utf-8'});
        result.push(sql);
    })

    return result.join('\r\n');
}

const decideSqlFile = function(){
    const buildDir = path.join(__dirname, "../build");
    const filename = versionRoot + ".sql";
    return path.join(buildDir,filename);    
}

exports.readSql = function(){
    const sqlBits = loadFiles();    
    const sqlFile = decideSqlFile();
    fs.writeFileSync(sqlFile,sqlBits); 
    return sqlBits;
}

exports.install = function(next){

    let dbConfig = {"user": "omar","host": "127.0.0.1","database": "thingy","password": "user","port": 5432}


    console.log(process.env.NODE_ENV === "test");    
    
    if(process.env.NODE_ENV === 'test'){        
      dbConfig = require("../test.db.config.json");
    }        
    

    const client = new pg.Client(dbConfig);
    const sqlFile = decideSqlFile();
    const sql = fs.readFileSync(sqlFile,{encoding:'utf-8'});    

    

    client.connect();
    return client.query(sql, function(err, result){        
        console.log(err);
        if(err){            
            next(err,null);
        }else{            
            next(null,result);
        }
    });
}