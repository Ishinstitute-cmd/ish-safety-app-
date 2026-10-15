import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_cache_service.dart';
import '../domain/flashcard_model.dart';

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  return FlashcardRepository();
});

class FlashcardRepository {
  Future<List<FlashcardModel>> getFlashcards({String? categoryId}) async {
    final all = _getSeedFlashcards();
    if (categoryId != null && categoryId != 'all') {
      return all.where((f) => f.categoryId == categoryId).toList();
    }
    return all;
  }

  List<FlashcardModel> _getSeedFlashcards() {
    return [
      FlashcardModel(
        id: 'fc-01',
        categoryId: '11111111-1111-1111-1111-111111111101', // NEBOSH
        categoryTitleEn: 'NEBOSH IGC',
        categoryTitleUr: 'نیبوش آئی جی سی',
        termEn: 'ALARP Principle',
        termUr: 'ALARP اصول',
        definitionEn:
            'As Low As Reasonably Practicable (ALARP): Weighing a risk against the trouble, time, and money needed to control it.',
        definitionUr:
            'جتنا معقول حد تک ممکن ہو خطرے کو کم کرنا: خطرے کی شدت اور اس کے کنٹرول پر آنے والے وقت، محنت اور لاگت کا موازنہ کر کے محفوظ حل اپنانا۔',
        exampleEn: 'Investing in automated machine guards when the cost is disproportionately small compared to the life-saving benefit.',
        exampleUr: 'مشینری پر خودکار سینسر لگانا تاکہ حادثات روکے جا سکیں۔',
      ),
      FlashcardModel(
        id: 'fc-02',
        categoryId: '11111111-1111-1111-1111-111111111101',
        categoryTitleEn: 'NEBOSH IGC',
        categoryTitleUr: 'نیبوش آئی جی سی',
        termEn: 'Hierarchy of Controls',
        termUr: 'کنٹرولز کا درجہ بندی نظام',
        definitionEn:
            'System used to eliminate or reduce hazards in order of effectiveness: Elimination -> Substitution -> Engineering -> Administrative -> PPE.',
        definitionUr:
            'خطرات پر قابو پانے کی سب سے مؤثر سے کم ترین ترتیب: خاتمہ -> متبادل -> انجینئرنگ -> انتظامی -> پی پی ای۔',
        exampleEn: 'Eliminating the need to work at height by assembling scaffolding structures at ground level first.',
        exampleUr: 'بلندی پر جانے کے بجائے زمین پر ہی اسٹرکچر جوڑ کر اوپر منتقل کرنا۔',
      ),
      FlashcardModel(
        id: 'fc-03',
        categoryId: '11111111-1111-1111-1111-111111111105', // Fire Safety
        categoryTitleEn: 'Fire Safety',
        categoryTitleUr: 'آگ سے حفاظت',
        termEn: 'PASS Technique',
        termUr: 'PASS طریقہ کار',
        definitionEn:
            'The four steps to operate a fire extinguisher: P (Pull pin), A (Aim at base), S (Squeeze lever), S (Sweep side to side).',
        definitionUr:
            'فائر ایکسٹنگوشر چلانے کے 4 مراحل: P (پن نکالیں)، A (آگ کے پیندے پر نشانہ باندھیں)، S (لیور دبائیں)، S (دائیں بائیں گھمائیں)۔',
        exampleEn: 'Always aim at the fuel source base, never at the rising flames.',
        exampleUr: 'شعلوں کے بجائے ہمیشہ آگ کی بنیاد پر نشانہ رکھیں۔',
      ),
      FlashcardModel(
        id: 'fc-04',
        categoryId: '11111111-1111-1111-1111-111111111104', // First Aid
        categoryTitleEn: 'First Aid',
        categoryTitleUr: 'ابتدائی طبی امداد',
        termEn: 'DRSABCD Protocol',
        termUr: 'DRSABCD ہنگامی طریقہ کار',
        definitionEn:
            'Emergency response sequence: Danger, Response, Send for help, Airway, Breathing, CPR, Defibrillation.',
        definitionUr:
            'ہنگامی ابتدائی طبی امداد کی ترتیب: خطرہ چیک کریں، ردعمل دیکھیں، مدد طلب کریں، سانس کی نالی کھولیں، سانس چیک کریں، سی پی آر دیں، ڈیفبریلیٹر لگائیں۔',
        exampleEn: 'Always ensure site danger (traffic, gas, electricity) is eliminated before approaching casualty.',
        exampleUr: 'مریض کے پاس جانے سے قبل یقینی بنائیں کہ آپ خود محفوظ ہیں۔',
      ),
      FlashcardModel(
        id: 'fc-05',
        categoryId: '11111111-1111-1111-1111-111111111108', // Construction
        categoryTitleEn: 'Construction Safety',
        categoryTitleUr: 'تعمیراتی حفاظت',
        termEn: 'Scaffold 4:1 Rule',
        termUr: 'سیڑھی اور اسکیفولڈ کا 4:1 اصول',
        definitionEn:
            'For every 4 units of vertical height, the base of an extension ladder must be placed 1 unit out from the wall.',
        definitionUr:
            'ہر 4 فٹ اونچائی کے لیے سیڑھی کا نچلا پیندہ دیوار سے 1 فٹ دور رکھا جائے تاکہ محفوظ زاویہ (75 ڈگری) بنے۔',
        exampleEn: 'A ladder reaching a 16-foot roof edge must have its base 4 feet away from the wall.',
        exampleUr: '16 فٹ اونچی چھت کے لیے سیڑھی کا پیندہ دیوار سے 4 فٹ فاصلے پر رکھیں۔',
      ),
      FlashcardModel(
        id: 'fc-06',
        categoryId: '11111111-1111-1111-1111-111111111106', // PPE
        categoryTitleEn: 'PPE Regulations',
        categoryTitleUr: 'حفاظتی سامان',
        termEn: 'Last Line of Defense',
        termUr: 'آخری دفاعی لائن',
        definitionEn:
            'PPE is the lowest ranked control because it only protects the wearer, does not remove the hazard, and relies heavily on correct human behavior.',
        definitionUr:
            'پی پی ای درجہ بندی میں سب سے نیچے ہے کیونکہ یہ خطرے کو ختم نہیں کرتا بلکہ صرف پہننے والے کے ذاتی استعمال اور درست سائز پر انحصار کرتا ہے۔',
        exampleEn: 'Relying solely on earplugs instead of enclosing a deafening machine inside soundproof casing.',
        exampleUr: 'مشین کا شور کم کرنے کے بجائے ورکرز کو صرف ایئر پلگ تھمانا۔',
      ),
    ];
  }
}
