var CronJob = require('cron').CronJob;
var childProcess = require('child_process');

function splitWithTail(str, delim, count) {
  var parts = str.split(delim);
  var tail = parts.slice(count).join(delim);
  var result = parts.slice(0, count);
  result.push(tail);
  return result;
}

function runCron(cronLine) {
  var cronElements = splitWithTail(cronLine, ' ', 5);
  var command = cronElements.pop();
  var handle;
  var schedule = cronElements.join(' ');
  console.log("Loading cron:", "'" + schedule + "'", "with command", "'" + command + "'");
  var job = new CronJob(schedule, function() {
    if (handle) {
      console.error("Process still running after next cron run", cronLine);
      handle.kill('SIGKILL');
    }
    var start = new Date().getTime();
    handle = childProcess.exec(command, function(err, stdout, stderr) {
      if (err) {
        return console.error("Error during running cron", cronLine, err.toString());
      }
      var runTime = new Date().getTime() - start;
      if (runTime > 5000) {
        console.warn('Command running too long from cron', "'" + cronLine + "'", runTime, "ms");
      }
      console.log(command, ':', stdout.toString(), stderr.toString());
      handle = null;
    });
  });
  job.start();
}

process.stdin.pipe(require('split')()).on('data', function(line) {
  line = line.replace(/^\s*(#.*)?/, '');
  if (line.match(/^\s*$/)) {
    return;
  }
  runCron(line);
});