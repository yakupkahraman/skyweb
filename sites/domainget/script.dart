import 'dart:convert';

void submit() {
  var domain = getInput('domain');
  var tld = getInput('tld');
  var repo = getInput('repo');

  if (domain == '' || tld == '' || repo == '') {
    setText('status', 'Tüm alanları doldurun.');
    return;
  }

  setText('status', 'Kaydediliyor...');
  var body =
      '{"domain":"' + domain + '","tld":"' + tld + '","repo":"' + repo + '"}';
  post('https://skydns.yakupkahraman.com/register', body, 'raw_status');
  setTimeout('parseResponse', 300);
}

void parseResponse() {
  var raw = getText('raw_status');
  if (raw == '...' || raw == '') {
    setTimeout('parseResponse', 200);
    return;
  }

  if (raw.startsWith('error:')) {
    setText('status', 'Bağlantı hatası oluştu.');
    return;
  }

  try {
    var data = jsonDecode(raw);
    if (data['error'] != null) {
      setText('status', 'Hata: ' + data['error'].toString());
    } else if (data['success'] == true) {
      setText('status', 'Domain başarıyla kaydedildi!');
    } else {
      setText('status', 'Kayıt işlemi tamamlandı.');
    }
  } catch (e) {
    setText('status', raw);
  }
}
