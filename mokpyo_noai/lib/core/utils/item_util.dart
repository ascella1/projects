import 'package:flutter/material.dart';

// assets/data/mokpyo_item.json의 아이템은 {id, name, desc}이며 name은
// "이모지 이름" 형식이다(예: "👑 전설의 왕관"). 이 파일이 아이템을
// "어떻게 그릴지"를 결정하는 유일한 곳이다 — 나중에 실제 이미지로 바꾸고
// 싶다면 itemVisual()만 고치면 된다. 자세한 안내는 CHARACTER_DESIGN.md 참고.

String itemEmoji(Map<String, String> item) => item['name']!.split(' ')[0];

String itemLabel(Map<String, String> item) {
  final name = item['name']!;
  return name.substring(name.indexOf(' ') + 1);
}

// 아이템을 화면에 그리는 단일 지점. 지금은 이모지 Text를 반환하지만,
// 나중에 실제 이미지 에셋으로 바꾸려면 이 함수 내부만 수정하면 된다.
Widget itemVisual(Map<String, String> item, {required double size}) {
  return Text(itemEmoji(item), style: TextStyle(fontSize: size));
}
