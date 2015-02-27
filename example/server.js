var net = require('net');

var server = net.createServer(function(c){
	c.setEncoding('utf8');

	c.on('connect', function(){
		console.log('connected');
	});

	c.on('data', function(data){
		console.log(data);
	});

	c.on('end', function(e){
		console.log('ended');
	});

	var cmd = +new Date() + '*enable';
	c.write(cmd.length + '*' + cmd);
}).listen(8888);