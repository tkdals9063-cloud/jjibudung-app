class StretchItem {
  final String name;
  final String description;
  final int time; // seconds

  StretchItem({
    required this.name,
    required this.description,
    required this.time,
  });
}

final List<StretchItem> stretchList = [
  StretchItem(
    name: "햄스트링 스트레칭",
    description: "허리 부담을 줄이고 골반 정렬을 돕습니다",
    time: 30,
  ),
  StretchItem(
    name: "둔근 스트레칭",
    description: "골반 안정화 및 요추 압력 감소",
    time: 30,
  ),
  StretchItem(
    name: "흉추 확장",
    description: "굽은 등 완화",
    time: 20,
  ),
  StretchItem(
    name: "목 전면 / 흉쇄유돌근",
    description: "거북목 완화",
    time: 20,
  ),
];