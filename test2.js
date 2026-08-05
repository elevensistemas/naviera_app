const http = require('http');

const req = http.request({
  hostname: 'localhost',
  port: 8888,
  path: '/ezviz-api/api/lapp/token/get',
  method: 'POST',
  headers: {'Content-Type': 'application/x-www-form-urlencoded'}
}, res => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    const token = JSON.parse(data).data.accessToken;
    
    const req2 = http.request({
      hostname: 'localhost',
      port: 8888,
      path: '/ezviz-api/api/lapp/camera/list',
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'}
    }, res2 => {
      let data2 = '';
      res2.on('data', chunk => data2 += chunk);
      res2.on('end', () => {
        const cams = JSON.parse(data2).data.filter(c => c.channelName.includes('BT.'));
        
        cams.forEach(cam => {
           console.log("Checking:", cam.channelName, cam.deviceSerial);
           const req3 = http.request({
              hostname: 'localhost',
              port: 8888,
              path: '/ezviz-api/api/lapp/v2/live/address/get',
              method: 'POST',
              headers: {'Content-Type': 'application/x-www-form-urlencoded'}
           }, res3 => {
              let data3 = '';
              res3.on('data', chunk => data3 += chunk);
              res3.on('end', () => {
                console.log("Response for " + cam.channelName + ":", data3);
              });
           });
           req3.write(`accessToken=${token}&deviceSerial=${cam.deviceSerial}&channelNo=1&protocol=2&quality=1`);
           req3.end();
        });
      });
    });
    req2.write(`accessToken=${token}&pageStart=0&pageSize=50`);
    req2.end();
  });
});
req.write('appKey=b7b99e5c45d64148a1492fb25b84ceb8&appSecret=2bd739f5c4614af0b33191f9a780fd42');
req.end();
