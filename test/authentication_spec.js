let assert = require('assert');
let {Helpers} = require('./helpers/index');
let helper = new Helpers();

describe('Authentication',function(){
        let db = null;
        before(function(done){  
            db = helper.getClient();      
            helper.initDb(function(err,res){
                db.query(`select * from register('neweamil@email.com','somepassword');`,function(err,res){
                    assert(err === null, err);                    
                    authResult = res.rows[0];
                    done();
                })
            });                                  
        })         
        describe('with a valid login',function(){
            let authResult = null;
            before(function(done){
                db.query(`select * from authenticate('neweamil@email.com','somepassword','local');`,function(err,res){
                    assert(err === null, err);      
                    console.log(res.rows)              
                    authResult = res.rows[0];
                    done();
                })
            })
            it("is successful",function(){
                assert.equal(true,authResult.success);
            })           
        })
})