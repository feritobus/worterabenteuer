import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'vocab_item.g.dart';

@HiveType(typeId: 2)
class VocabItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String german;

  @HiveField(2)
  String spanish;

  @HiveField(3)
  String type; // 'word' | 'sentence'

  @HiveField(4)
  String? grammarNote;

  @HiveField(5)
  bool dominated;

  @HiveField(6)
  bool voiceBonus;

  @HiveField(7)
  int flashCardViews;

  @HiveField(8)
  int typedCorrect;

  @HiveField(9)
  int handwrittenAttempts;

  @HiveField(10)
  int handwrittenCorrect;

  @HiveField(11)
  int voiceAttempts;

  @HiveField(12)
  int voiceCorrect;

  @HiveField(13)
  int order;

  @HiveField(14)
  bool addedToReviewRound;

  @HiveField(15)
  bool reviewRoundPassed;

  @HiveField(16)
  String? imageUrl;

  @HiveField(17)
  String? audioUrl;

  VocabItem({
    required this.id,
    required this.german,
    required this.spanish,
    required this.type,
    required this.order,
    this.grammarNote,
    this.dominated = false,
    this.voiceBonus = false,
    this.flashCardViews = 0,
    this.typedCorrect = 0,
    this.handwrittenAttempts = 0,
    this.handwrittenCorrect = 0,
    this.voiceAttempts = 0,
    this.voiceCorrect = 0,
    this.addedToReviewRound = false,
    this.reviewRoundPassed = false,
    this.imageUrl,
    this.audioUrl,
  });

  Map<String, dynamic> toFirestore() => {
        'german': german,
        'spanish': spanish,
        'type': type,
        'order': order,
        'grammarNote': grammarNote,
        'dominated': dominated,
        'voiceBonus': voiceBonus,
        'flashCardViews': flashCardViews,
        'typedCorrect': typedCorrect,
        'handwrittenAttempts': handwrittenAttempts,
        'handwrittenCorrect': handwrittenCorrect,
        'voiceAttempts': voiceAttempts,
        'voiceCorrect': voiceCorrect,
        'addedToReviewRound': addedToReviewRound,
        'reviewRoundPassed': reviewRoundPassed,
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
      };

  factory VocabItem.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return VocabItem(
      id: doc.id,
      german: d['german'] as String? ?? '',
      spanish: d['spanish'] as String? ?? '',
      type: d['type'] as String? ?? 'word',
      order: d['order'] as int? ?? 0,
      grammarNote: d['grammarNote'] as String?,
      dominated: d['dominated'] as bool? ?? false,
      voiceBonus: d['voiceBonus'] as bool? ?? false,
      flashCardViews: d['flashCardViews'] as int? ?? 0,
      typedCorrect: d['typedCorrect'] as int? ?? 0,
      handwrittenAttempts: d['handwrittenAttempts'] as int? ?? 0,
      handwrittenCorrect: d['handwrittenCorrect'] as int? ?? 0,
      voiceAttempts: d['voiceAttempts'] as int? ?? 0,
      voiceCorrect: d['voiceCorrect'] as int? ?? 0,
      addedToReviewRound: d['addedToReviewRound'] as bool? ?? false,
      reviewRoundPassed: d['reviewRoundPassed'] as bool? ?? false,
      imageUrl: d['imageUrl'] as String?,
      audioUrl: d['audioUrl'] as String?,
    );
  }

  bool get isWord => type == 'word';
  bool get isSentence => type == 'sentence';
}
