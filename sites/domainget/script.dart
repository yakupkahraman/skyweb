void submit() {
  var domain = getInput('domain');
  var tld = getInput('tld');
  var repo = getInput('repo');

  if (domain == '' || tld == '' || repo == '') {
    setText('status', 'Tüm alanları doldurun.');
    return;
  }

  var body =
      '{"domain":"' + domain + '","tld":"' + tld + '","repo":"' + repo + '"}';
  post('https://skydns.yakupkahraman.com/register', body, 'status');
}
