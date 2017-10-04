const program = require('commander');
const builder = require('./lib/builder');

program
.command('build [env]')
.description('Build the SQL files our project')
.action(function(){    
      builder.readSql();
});



program
.command('install')
.description('Build the SQL files our project')
.action(function(){ 
  let target = process.env.NODE_ENV || `development`;  
  console.log(`Installing into`, target);   
  builder.install(function(err,result){    
      process.exit(0);
  });    
  
});

program.parse(process.argv);