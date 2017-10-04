let assert = require('assert');
let {Helpers} = require('./helpers/index');
let helper = new Helpers();

describe('Registration',function(){
        let db = null;
        before(function(done){  
            db = helper.getClient();      
            helper.initDb(done);            
        })         
        describe('with valid creds',function(){
            let regResult = null;
            before(function(done){
                db.query(`select * from register('neweamil@email.com','somepassword');`,function(err,res){
                    assert(err === null, err);                    
                    regResult = res.rows[0];
                    done();
                })
            })
            it("is successful",function(){
                assert.equal(true,regResult.success);
            })
            it("returns new id",function(){
                assert(regResult.new_id);
            })
            it("returns validatio token",function(){
                assert(regResult.validation_token);
            });
        })
        describe('trying an existing user',function(){
            let regResult = null;
            before(function(done){

                db.query(`select * from register('neweamil@email.com','somepassword');`,function(err,res){                    
                    assert(err === null, err);                    
                    regResult = res.rows[0];                    
                    done();
                })
            })
            it('is not successful',function(){                
                assert.equal(false, regResult.success);
            })
        })
    })