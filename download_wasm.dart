import 'dart:io';

void main() async {
  final client = HttpClient();
  
  final wasmReq = await client.getUrl(Uri.parse('https://cdnjs.cloudflare.com/ajax/libs/sql.js/1.8.0/sql-wasm.wasm'));
  final wasmRes = await wasmReq.close();
  await wasmRes.pipe(File('web/sql-wasm.wasm').openWrite());
  
  final jsReq = await client.getUrl(Uri.parse('https://cdnjs.cloudflare.com/ajax/libs/sql.js/1.8.0/sql-wasm.js'));
  final jsRes = await jsReq.close();
  await jsRes.pipe(File('web/sql-wasm.js').openWrite());
  
  print('Downloaded sql.js files successfully.');
}
