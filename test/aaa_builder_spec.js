let builder = require('../lib/builder');
let assert = require('assert');
let {Helpers} = require('./helpers/index');
let helper = new Helpers();


describe('SQL BUILDER',function(){
    
    before(function(done){        
        helper.connect();
        helper.initDb(done);
    })         
    it('loads',function(){
        assert(builder)
    })
    describe('loading sql',function(){
        it('returns a sql string',function(){            
            assert(builder.readSql());
        })
    })
})