enum EmploymentStatus { employee, selfEmployed, freelancer, jobSeeker, student, none }

enum MilitaryStatus { notApplicable, active, completed, exempted }

enum HousingStatus { noHouse, renting, owned }

enum Gender { male, female, other }

extension EmploymentStatusLabel on EmploymentStatus {
  String get label => switch (this) {
        EmploymentStatus.employee => '직장인',
        EmploymentStatus.selfEmployed => '자영업자',
        EmploymentStatus.freelancer => '프리랜서',
        EmploymentStatus.jobSeeker => '구직중',
        EmploymentStatus.student => '학생',
        EmploymentStatus.none => '무직',
      };
}

extension HousingStatusLabel on HousingStatus {
  String get label => switch (this) {
        HousingStatus.noHouse => '무주택',
        HousingStatus.renting => '전월세',
        HousingStatus.owned => '자가',
      };
}

extension GenderLabel on Gender {
  String get label => switch (this) {
        Gender.male => '남성',
        Gender.female => '여성',
        Gender.other => '기타',
      };
}

/// 사용자 프로필 — 온보딩/프로필 화면에서 입력, 자격 판정 룰 엔진의 입력값(docs/02 user_profile 참고).
/// 서버가 없는 MVP이므로 순수 in-memory 값 객체로 둔다.
class UserProfile {
  final int? birthYear;
  final Gender? gender;
  final String? regionCode; // docs/02 region.code 참고 (시/도 단위로 단순화)
  final int? incomeAnnual; // KRW
  final EmploymentStatus? employmentStatus;
  final bool? isStudent;
  final MilitaryStatus? militaryStatus;
  final bool? isMarried;
  final int? childrenCount;
  final HousingStatus? housingStatus;
  final bool? hasDisability;
  final bool? isSmallBusinessOwner;
  final bool? isFreelancer;

  const UserProfile({
    this.birthYear,
    this.gender,
    this.regionCode,
    this.incomeAnnual,
    this.employmentStatus,
    this.isStudent,
    this.militaryStatus,
    this.isMarried,
    this.childrenCount,
    this.housingStatus,
    this.hasDisability,
    this.isSmallBusinessOwner,
    this.isFreelancer,
  });

  int? get age {
    if (birthYear == null) return null;
    return DateTime.now().year - birthYear! + 1; // 만 나이가 아닌 한국식 세는나이 단순 근사
  }

  bool get isOnboarded => birthYear != null && regionCode != null && employmentStatus != null;

  /// 룰 엔진이 참조하는 필드 맵 (docs/05 RuleCondition.field 와 대응).
  Map<String, dynamic> toFieldMap() => {
        'age': age,
        'gender': gender?.name,
        'regionCode': regionCode,
        'incomeAnnual': incomeAnnual,
        'employmentStatus': employmentStatus?.name,
        'isStudent': isStudent,
        'militaryStatus': militaryStatus?.name,
        'isMarried': isMarried,
        'childrenCount': childrenCount,
        'housingStatus': housingStatus?.name,
        'hasDisability': hasDisability,
        'isSmallBusinessOwner': isSmallBusinessOwner,
        'isFreelancer': isFreelancer,
      };

  UserProfile copyWith({
    int? birthYear,
    Gender? gender,
    String? regionCode,
    int? incomeAnnual,
    EmploymentStatus? employmentStatus,
    bool? isStudent,
    MilitaryStatus? militaryStatus,
    bool? isMarried,
    int? childrenCount,
    HousingStatus? housingStatus,
    bool? hasDisability,
    bool? isSmallBusinessOwner,
    bool? isFreelancer,
  }) {
    return UserProfile(
      birthYear: birthYear ?? this.birthYear,
      gender: gender ?? this.gender,
      regionCode: regionCode ?? this.regionCode,
      incomeAnnual: incomeAnnual ?? this.incomeAnnual,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      isStudent: isStudent ?? this.isStudent,
      militaryStatus: militaryStatus ?? this.militaryStatus,
      isMarried: isMarried ?? this.isMarried,
      childrenCount: childrenCount ?? this.childrenCount,
      housingStatus: housingStatus ?? this.housingStatus,
      hasDisability: hasDisability ?? this.hasDisability,
      isSmallBusinessOwner: isSmallBusinessOwner ?? this.isSmallBusinessOwner,
      isFreelancer: isFreelancer ?? this.isFreelancer,
    );
  }
}

const regionOptions = <String, String>{
  'seoul': '서울',
  'gyeonggi': '경기',
  'incheon': '인천',
  'busan': '부산',
  'daegu': '대구',
  'daejeon': '대전',
  'gwangju': '광주',
  'sejong': '세종',
  'gangwon': '강원',
  'chungcheong': '충청',
  'jeolla': '전라',
  'gyeongsang': '경상',
  'jeju': '제주',
};
