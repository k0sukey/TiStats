var net = require('net');

var client = net.createConnection({
		port: 8888
	}, function(){
		var request = JSON.stringify({
				seq: +new Date(),
				type: 'request',
				command: 'continue'
			});
		client.write('Content-Length: ' + Buffer.byteLength(request, 'utf8') + '\r\n\r\n' + request);
		console.log('connected');

		request = JSON.stringify({
			seq: +new Date(),
			type: 'request',
			command: 'evaluate',
			arguments: {
				expression: 'var TiStats = require(\'be.k0suke.tistats\');',
				global: true
			}
		});
		client.write('Content-Length: ' + Buffer.byteLength(request, 'utf8') + '\r\n\r\n' + request);

		setTimeout(function(){
			setInterval(function(){
				var request = JSON.stringify({
						seq: +new Date(),
						type: 'request',
						command: 'evaluate',
						arguments: {
							expression: 'TiStats.stats();',
							global: true
						}
					});
				client.write('Content-Length: ' + Buffer.byteLength(request, 'utf8') + '\r\n\r\n' + request);
			}, 1000);
		}, 1000);
	});
client.setEncoding('utf8');

client.on('data', function(data){
console.log('------------------------------------------------------------');
console.log(data);
	var response = data.split('\r\n\r\n');
	try {
		var json = JSON.parse(response[1]);
	} catch(e) {}
});

client.on('end', function(){
	console.log('ended');
});