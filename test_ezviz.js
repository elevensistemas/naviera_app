const http = require('http');
const https = require('https');
const fs = require('fs');

let out = "";

const req = http.request({
  hostname: 'open.ezvizlife.com',
  path: '/api/lapp/token/get',
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
}, res => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      const parsed = JSON.parse(data);
      const token = parsed.data.accessToken;
      
      const req2 = http.request({
        hostname: 'open.ezvizlife.com',
        path: '/api/lapp/camera/list',
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
      }, res2 => {
        let data2 = '';
        res2.on('data', chunk => data2 += chunk);
        res2.on('end', () => {
          const cams = JSON.parse(data2).data || [];
          out += "Found Cameras:\n";
          cams.forEach(c => {
             out += `- Serial: ${c.deviceSerial}, Name: ${c.channelName}\n`;
          });

          if (cams.length > 0) {
            const req3 = http.request({
              hostname: 'open.ezvizlife.com',
              path: '/api/lapp/v2/live/address/get',
              method: 'POST',
              headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
            }, res3 => {
               let data3 = '';
               res3.on('data', chunk => data3 += chunk);
               res3.on('end', () => {
                 out += "\nAddress for first camera (protocol=2):\n" + data3 + "\n";
                 fs.writeFileSync('cams_output.txt', out);
               });
            });
            req3.write(`accessToken=${token}&deviceSerial=${cams[0].deviceSerial}&channelNo=1&protocol=2&quality=1`);
            req3.end();
          } else {
             fs.writeFileSync('cams_output.txt', out);
          }
        });
      });
      req2.write(`accessToken=${token}&pageStart=0&pageSize=50`);
      req2.end();
    } catch (e) {
      fs.writeFileSync('cams_output.txt', "Error: " + e.message + "\n" + data);
    }
  });
});
req.write('appKey=b7b99e5c45d64148a1492fb25b84ceb8&appSecret=2bd739f5c4614af0b33191f9a780fd42');
req.end();
