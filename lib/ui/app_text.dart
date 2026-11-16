import 'package:flutter/material.dart' as material;

/// App copy is translated at build time, so existing screens react immediately
/// when MaterialApp's locale changes. English remains the fallback for copy
/// that has not been localized yet.
class AppCopy {
  static String of(material.BuildContext context, String english) {
    if (material.Localizations.localeOf(context).languageCode != 'th') {
      return english;
    }
    final exact = _thai[english] ?? _thaiLower[english.toLowerCase()];
    if (exact != null) return exact;
    if (english.contains(' · ')) {
      return english.split(' · ').map((part) => of(context, part)).join(' · ');
    }
    var result = english;
    for (final entry in _inlineThai.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  static final Map<String, String> _thaiLower = {
    for (final entry in _thai.entries) entry.key.toLowerCase(): entry.value,
  };

  static const Map<String, String> _thai = {
    'Today': 'วันนี้',
    'Language': 'ภาษา',
    'e.g. 72.5': 'เช่น 72.5',
    'e.g. 175': 'เช่น 175',
    'Optional': 'ไม่บังคับ',
    'Your name': 'ชื่อของคุณ',
    'At least 8 characters': 'อย่างน้อย 8 ตัวอักษร',
    'Backup passphrase': 'รหัสผ่านไฟล์สำรอง',
    'New local passphrase': 'รหัสผ่านใหม่ในเครื่อง',
    'Description': 'รายละเอียด',
    'Optional. Set it later when a fight is scheduled.':
        'ไม่บังคับ ตั้งภายหลังเมื่อกำหนดวันชกแล้ว',
    'Optional. Set it when your next fight is confirmed.':
        'ไม่บังคับ ตั้งเมื่อยืนยันวันชกครั้งถัดไป',
    'Used only for weight trend and safety monitoring.':
        'ใช้ติดตามแนวโน้มน้ำหนักและความปลอดภัยเท่านั้น',
    'Weight data is for safety monitoring, not weight-cut advice.':
        'ข้อมูลน้ำหนักใช้ติดตามความปลอดภัย ไม่ใช่คำแนะนำในการลดน้ำหนัก',
    'Choose the language used in the app.': 'เลือกภาษาที่ใช้ในแอพ',
    'English': 'English',
    'ไทย': 'ไทย',
    'Apple Health': 'Apple Health',
    'Training': 'การซ้อม',
    'Food': 'อาหาร',
    'Camp': 'แคมป์',
    'Trends': 'แนวโน้ม',
    'Settings': 'ตั้งค่า',
    'Unavailable': 'ไม่มีข้อมูล',
    'No data': 'ไม่มีข้อมูล',
    'Ready': 'พร้อม',
    'Caution': 'ระวัง',
    'Restricted': 'จำกัด',
    'Learning baseline': 'กำลังเรียนรู้ค่าพื้นฐาน',
    'Latest available': 'ข้อมูลล่าสุดที่มี',
    'Cancel': 'ยกเลิก',
    'Continue': 'ดำเนินการต่อ',
    'Save': 'บันทึก',
    'Start': 'เริ่ม',
    'Complete': 'เสร็จสิ้น',
    'Dismiss': 'ปิด',
    'Delete': 'ลบ',
    'Restore': 'กู้คืน',
    'Yes': 'ใช่',
    'No': 'ไม่',
    'Low': 'น้อย',
    'Medium': 'ปานกลาง',
    'High': 'มาก',
    'Light': 'เบา',
    'Moderate': 'ปานกลาง',
    'Heavy': 'หนัก',
    'Sore': 'เมื่อย',
    'OK': 'ปกติ',
    'Good': 'ดี',
    'Bad': 'ไม่ดี',
    'Brain': 'สมอง',
    'Fuel & Weight': 'พลังงานและน้ำหนัก',
    'Sleep & Heart': 'การนอนและหัวใจ',
    'Power & Speed': 'พลังและความเร็ว',
    'Body': 'ร่างกาย',
    'Mind': 'จิตใจ',
    'Sparring': 'ซ้อมชก',
    'Boxing / Technical': 'มวย / เทคนิค',
    'Boxing / Technical Boxing': 'มวย / เทคนิค',
    'Conditioning': 'ความทนทาน',
    'Strength': 'ฝึกกำลัง',
    'Today’s recovery': 'การฟื้นตัววันนี้',
    'You can train': 'ซ้อมได้',
    'Avoid today': 'ควรงดวันนี้',
    'Primary limiter': 'ปัจจัยหลักที่ถ่วงวันนี้',
    'One thing tonight': 'สิ่งเดียวที่ทำคืนนี้',
    'Connected data': 'ข้อมูลที่เชื่อมต่อ',
    'Last sleep': 'การนอนล่าสุด',
    'Last HRV': 'HRV ล่าสุด',
    'Resting HR': 'ชีพจรขณะพัก',
    'Camp start': 'เริ่มแคมป์',
    'Fight night': 'วันชก',
    'Set next fight date': 'ตั้งวันชกครั้งถัดไป',
    'No fight scheduled': 'ยังไม่กำหนดวันชก',
    'No upcoming fight scheduled': 'ยังไม่กำหนดวันชกครั้งถัดไป',
    'Safety first': 'ความปลอดภัยมาก่อน',
    'Safety warning overrides readiness':
        'คำเตือนความปลอดภัยมีผลเหนือสถานะความพร้อม',
    'Why is HRV unavailable?': 'ทำไม HRV ยังไม่มีข้อมูล?',
    'Review safety details →': 'ดูรายละเอียดความปลอดภัย →',
    'View trends': 'ดูแนวโน้ม',
    'Training Today': 'การซ้อมวันนี้',
    'Four training types': 'การซ้อม 4 ประเภท',
    'Log training': 'บันทึกการซ้อม',
    'Log after training': 'บันทึกหลังซ้อม',
    'Log another session →': 'บันทึกการซ้อมอีกครั้ง →',
    'Training saved today': 'บันทึกการซ้อมวันนี้แล้ว',
    'View FightCamp performance →': 'ดูผล FightCamp →',
    'Latest session': 'เซสชันล่าสุด',
    'FightCamp': 'FightCamp',
    'This app does not diagnose concussion or provide medical clearance.':
        'แอพนี้ไม่วินิจฉัยภาวะสมองกระทบกระเทือนหรือรับรองความพร้อมทางการแพทย์',
    'Head-impact follow-up': 'ติดตามอาการหลังศีรษะถูกกระแทก',
    'Record clinician guidance': 'บันทึกคำแนะนำจากบุคลากรแพทย์',
    'Record external plan?': 'บันทึกแผนจากผู้เชี่ยวชาญ?',
    'Record plan': 'บันทึกแผน',
    'Next-morning check': 'เช็กอีกครั้งเช้าวันถัดไป',
    'What changed this morning': 'เช้านี้เปลี่ยนไปอย่างไร',
    'DID IT ACTUALLY WORK?': 'สิ่งที่ทำช่วยหรือไม่?',
    'ONE THING, THEN SLEEP': 'ทำอย่างเดียว แล้วพักผ่อน',
    'Tonight': 'คืนนี้',
    'Last night': 'เมื่อคืน',
    'Complete action': 'ทำเสร็จแล้ว',
    'See today’s recovery': 'ดูการฟื้นตัววันนี้',
    'Morning Check-in': 'เช็กอินตอนเช้า',
    'About 20 seconds': 'ใช้เวลาประมาณ 20 วินาที',
    'Watch data': 'ข้อมูลจากอุปกรณ์',
    'Morning weight': 'น้ำหนักตอนเช้า',
    'Morning weight (kg)': 'น้ำหนักตอนเช้า (กก.)',
    'Use this weight': 'ใช้น้ำหนักนี้',
    'Urine colour': 'สีปัสสาวะ',
    'How do you feel?': 'วันนี้รู้สึกอย่างไร?',
    'New symptoms after head contact?': 'มีอาการใหม่หลังศีรษะถูกกระแทกหรือไม่?',
    'Check-in': 'เช็กอิน',
    'After Training': 'หลังซ้อม',
    'Training type': 'ประเภทการซ้อม',
    'Rounds': 'ยก',
    'Duration': 'ระยะเวลา',
    'Intensity': 'ความหนัก',
    'Head contact': 'การกระแทกศีรษะ',
    'Soreness / pain': 'อาการเมื่อย / ปวด',
    'How does it feel?': 'รู้สึกอย่างไร?',
    'Save training': 'บันทึกการซ้อม',
    'Nutrition': 'โภชนาการ',
    'Post-training meal?': 'กินอาหารหลังซ้อมหรือยัง?',
    'Protein completed?': 'ได้รับโปรตีนเพียงพอหรือยัง?',
    'Carbs today': 'คาร์โบไฮเดรตวันนี้',
    'Save nutrition': 'บันทึกโภชนาการ',
    'Open food journal →': 'เปิดบันทึกอาหาร →',
    'Food photo journal': 'บันทึกรูปอาหาร',
    'Snap your plate': 'ถ่ายรูปอาหาร',
    'Camera': 'กล้อง',
    'Gallery': 'รูปภาพ',
    'Add a food photo': 'เพิ่มรูปอาหาร',
    'Meal': 'มื้ออาหาร',
    'Food and serving size': 'อาหารและปริมาณ',
    'Save meal': 'บันทึกมื้ออาหาร',
    'No meals logged yet': 'ยังไม่มีบันทึกอาหาร',
    'Sleep': 'การนอน',
    'Create profile': 'สร้างโปรไฟล์',
    'Display name': 'ชื่อที่แสดง',
    'Next fight date': 'วันชกครั้งถัดไป',
    'Current weight (kg)': 'น้ำหนักปัจจุบัน (กก.)',
    'Height (cm)': 'ส่วนสูง (ซม.)',
    'Target weight (kg)': 'น้ำหนักเป้าหมาย (กก.)',
    'Local passphrase': 'รหัสผ่านในเครื่อง',
    'I accept the Privacy Notice': 'ฉันยอมรับประกาศความเป็นส่วนตัว',
    'BOXER RECOVERY': 'BOXER RECOVERY',
    'WELCOME BACK': 'ยินดีต้อนรับกลับ',
    'YOU ARE READY': 'พร้อมเริ่มต้น',
    'HEALTH DATA · STEP 2': 'ข้อมูลสุขภาพ · ขั้นตอนที่ 2',
    'Own your recovery.': 'ดูแลการฟื้นตัวของคุณ',
    'Boxer Recovery': 'Boxer Recovery',
    'Connect health data.': 'เชื่อมต่อข้อมูลสุขภาพ',
    'Connect Apple Health': 'เชื่อมต่อ Apple Health',
    'Sources': 'แหล่งข้อมูล',
    'Automatically tracked': 'ติดตามอัตโนมัติ',
    'Manual inputs': 'ข้อมูลที่กรอกเอง',
    'Learning your baseline — Day 1 of 7':
        'กำลังเรียนรู้ค่าพื้นฐานของคุณ — วันที่ 1 จาก 7',
    'Restore from encrypted backup': 'กู้คืนจากไฟล์สำรองที่เข้ารหัส',
    'Restore athlete backup': 'กู้คืนข้อมูลนักกีฬา',
    'Use this athlete profile?': 'ใช้โปรไฟล์นักกีฬานี้?',
    'Unlock': 'ปลดล็อก',
    'No fight scheduled · Choose date': 'ยังไม่กำหนดวันชก · เลือกวันที่',
    'Athlete': 'นักกีฬา',
    'Edit profile': 'แก้ไขโปรไฟล์',
    'Edit Profile': 'แก้ไขโปรไฟล์',
    'Save profile': 'บันทึกโปรไฟล์',
    'Remove scheduled fight': 'ลบวันชกที่กำหนดไว้',
    'Connected sources': 'แหล่งข้อมูลที่เชื่อมต่อ',
    'Connected Sources': 'แหล่งข้อมูลที่เชื่อมต่อ',
    'Source used for recovery assessment': 'แหล่งข้อมูลที่ใช้ประเมินการฟื้นตัว',
    'Sync now': 'ซิงก์ตอนนี้',
    'Disconnect and clear imported data':
        'ยกเลิกการเชื่อมต่อและลบข้อมูลที่นำเข้า',
    'Notifications': 'การแจ้งเตือน',
    'Privacy & consent': 'ความเป็นส่วนตัวและความยินยอม',
    'Data backup': 'สำรองข้อมูล',
    'Export encrypted backup': 'ส่งออกไฟล์สำรองที่เข้ารหัส',
    'Restore from backup': 'กู้คืนจากไฟล์สำรอง',
    'Lock app': 'ล็อกแอพ',
    'Delete account and data': 'ลบบัญชีและข้อมูล',
    'Delete local account?': 'ลบบัญชีในเครื่อง?',
    'Replace local data?': 'แทนที่ข้อมูลในเครื่อง?',
    'Weight trend': 'แนวโน้มน้ำหนัก',
    'Recovery trend & safety': 'แนวโน้มการฟื้นตัวและความปลอดภัย',
    'View all trends': 'ดูแนวโน้มทั้งหมด',
    'Recovery history': 'ประวัติการฟื้นตัว',
    'Recovery domains': 'ด้านการฟื้นตัว',
    'Sleep & heart': 'การนอนและหัวใจ',
    'Weight & punch performance': 'น้ำหนักและผลงานการชก',
    'Training load': 'ภาระการซ้อม',
    'Minutes by training type': 'นาทีแยกตามประเภทการซ้อม',
    'Sessions in this period': 'จำนวนครั้งในช่วงนี้',
    'No training sessions logged in this period.':
        'ไม่มีบันทึกการซ้อมในช่วงนี้',
    'No primary limiter recorded in this period.':
        'ไม่มีบันทึกปัจจัยหลักในช่วงนี้',
    'Past scores appear after check-ins or logs. Missing days stay blank.':
        'คะแนนย้อนหลังจะปรากฏหลังเช็กอินหรือบันทึกข้อมูล วันที่ไม่มีข้อมูลจะเว้นว่าง',
    'Each domain has its own score. No overall average.':
        'แต่ละด้านมีคะแนนของตัวเอง ไม่มีคะแนนเฉลี่ยรวม',
    'today': 'วันนี้',
    'camp start': 'เริ่มแคมป์',
    'first log': 'บันทึกแรก',
    'fight night': 'วันชก',
    'build': 'ช่วงสร้างพื้นฐาน',
    'peak': 'ช่วงพีค',
    'taper': 'ช่วงลดภาระซ้อม',
    'base': 'ช่วงฐาน',
    'fight week': 'สัปดาห์ชก',
    'no camp': 'ยังไม่มีแคมป์',
    'INSUFFICIENT_DATA': 'ข้อมูลไม่เพียงพอ',
    'AVAILABLE': 'ซ้อมได้',
    'MODIFIED': 'ปรับการซ้อม',
    'AVOID': 'ควรงด',
    'READY': 'พร้อม',
    'CAUTION': 'ระวัง',
    'RESTRICTED': 'จำกัด',
    'More data needed': 'ต้องมีข้อมูลเพิ่ม',
    'No primary limiter from the available data':
        'ยังไม่พบปัจจัยหลักจากข้อมูลที่มี',
    'No Clear Pattern': 'ยังไม่เห็นรูปแบบชัดเจน',
    'Not Enough Data': 'ข้อมูลยังไม่เพียงพอ',
    'Possible Benefit': 'อาจมีผลดี',
    'Usually Helpful': 'มักมีส่วนช่วย',
    'Within your personal baseline': 'อยู่ในช่วงค่าพื้นฐานของคุณ',
    'HRV below your baseline': 'HRV ต่ำกว่าค่าพื้นฐานของคุณ',
    'Resting HR above your baseline': 'ชีพจรขณะพักสูงกว่าค่าพื้นฐานของคุณ',
    'Sleep below your baseline': 'นอนน้อยกว่าค่าพื้นฐานของคุณ',
    'Urine colour suggests hydration attention':
        'สีปัสสาวะบ่งชี้ว่าควรใส่ใจเรื่องน้ำ',
    'Post-training meal missed': 'ยังไม่ได้กินอาหารหลังซ้อม',
    'Protein plan incomplete': 'ยังได้รับโปรตีนไม่ครบตามแผน',
    'Long hard conditioning increases refuelling attention':
        'การฝึกความทนทานหนักและนานทำให้ต้องใส่ใจการเติมพลัง',
    'Long hard conditioning session reported recently':
        'เพิ่งบันทึกการฝึกความทนทานที่หนักและนาน',
    'Long hard technical boxing reported':
        'บันทึกการซ้อมเทคนิคมวยที่หนักและนาน',
    'Long hard strength or technical load reported; a power change has not been measured':
        'มีการฝึกกำลังหรือเทคนิคหนักและนาน แต่ยังไม่มีข้อมูลวัดการเปลี่ยนแปลงของพลัง',
    'Learning your FightCamp punch baseline':
        'กำลังเรียนรู้ค่าพื้นฐานจำนวนหมัดจาก FightCamp',
    'Punch output is below your personal FightCamp baseline.':
        'ผลการชกต่ำกว่าค่าพื้นฐาน FightCamp ของคุณ',
    'Punch output is below your personal baseline; keep technique slow and no-contact.':
        'ผลการชกต่ำกว่าค่าพื้นฐานของคุณ ควรซ้อมเทคนิคช้า ๆ แบบไม่มีการปะทะ',
    'Plan a regular recovery meal': 'วางแผนมื้ออาหารเพื่อฟื้นตัวตามปกติ',
    'Prepare for a quiet evening': 'เตรียมช่วงเย็นที่สงบ',
    'Prepare for an earlier bedtime': 'เตรียมเข้านอนให้เร็วขึ้น',
    'Protect recovery before tomorrow.':
        'ให้ความสำคัญกับการฟื้นตัวก่อนวันพรุ่งนี้',
    '10 min gentle mobility': 'ขยับร่างกายเบา ๆ 10 นาที',
    '10 min breathing down-regulation': 'ฝึกหายใจผ่อนคลาย 10 นาที',
    'Sparring can be considered': 'อาจพิจารณาซ้อมชกได้',
    'Technical boxing is an option': 'ซ้อมมวยเทคนิคได้',
    'Conditioning is an option': 'ฝึกความทนทานได้',
    'Strength is an option': 'ฝึกกำลังได้',
    'Avoid sparring today': 'งดซ้อมชกวันนี้',
    'Skip sparring today': 'งดซ้อมชกวันนี้',
    'Avoid hard contact': 'งดการปะทะหนัก',
    'Hard sparring': 'ซ้อมชกหนัก',
    'Hard conditioning': 'ฝึกความทนทานหนัก',
    'Hard pads or bag work': 'ซ้อมเป้าหรือกระสอบหนัก',
    'Heavy strength': 'ฝึกกำลังหนัก',
    'Skip heavy lifting today': 'งดยกน้ำหนักหนักวันนี้',
    'Keep technical work light': 'ซ้อมเทคนิคเบา ๆ',
    'Easy aerobic work only': 'ทำกิจกรรมแอโรบิกเบา ๆ เท่านั้น',
    'Easy conditioning': 'ฝึกความทนทานเบา ๆ',
    'No-contact footwork': 'ฝึกฟุตเวิร์กแบบไม่มีการปะทะ',
    'Footwork only; rest the shoulder': 'ฝึกฟุตเวิร์กเท่านั้น ให้หัวไหล่พัก',
    'Light strength away from sore areas': 'ฝึกกำลังเบา ๆ โดยเลี่ยงจุดที่ปวด',
    'Leg-loading conditioning': 'ฝึกความทนทานที่ลงน้ำหนักขา',
    'Avoid leg-loading conditioning': 'งดการฝึกความทนทานที่ลงน้ำหนักขา',
    'Unsupervised sparring': 'ซ้อมชกโดยไม่มีผู้ดูแล',
    'Unplanned head-contact drills': 'ฝึกที่มีการกระแทกศีรษะนอกแผน',
    'Training outside the clinician plan': 'ซ้อมนอกแผนของบุคลากรแพทย์',
    'Pause training and get assessed': 'หยุดซ้อมและเข้ารับการประเมิน',
    'Pause loading and get assessed': 'หยุดการฝึกที่ลงแรงและเข้ารับการประเมิน',
    'Follow your clinician’s return-to-contact plan':
        'ทำตามแผนกลับสู่การซ้อมที่มีการปะทะจากบุคลากรแพทย์',
    'Follow your clinician\'s return-to-contact plan':
        'ทำตามแผนกลับสู่การซ้อมที่มีการปะทะจากบุคลากรแพทย์',
    'Follow your clinician’s activity plan': 'ทำตามแผนกิจกรรมจากบุคลากรแพทย์',
    'Follow your clinician\'s activity plan': 'ทำตามแผนกิจกรรมจากบุคลากรแพทย์',
    'Follow the clinician’s activity plan': 'ทำตามแผนกิจกรรมจากบุคลากรแพทย์',
    'Complete the check-in and build a personal baseline before a positive training suggestion.':
        'เช็กอินและสะสมค่าพื้นฐานส่วนบุคคลก่อนรับคำแนะนำให้ซ้อม',
    'Head pain or symptoms after contact need qualified evaluation before further training.':
        'อาการปวดศีรษะหรืออาการอื่นหลังการปะทะควรได้รับการประเมินจากผู้เชี่ยวชาญก่อนซ้อมต่อ',
    'Severe pain was reported. Avoid training until the affected area is assessed.':
        'มีรายงานอาการปวดรุนแรง งดซ้อมจนกว่าบริเวณที่ปวดจะได้รับการประเมิน',
    'Repeated heavy head contact was logged in the last 7 days.':
        'มีการบันทึกการกระแทกศีรษะหนักซ้ำในช่วง 7 วันที่ผ่านมา',
    'Fight-week plan favours avoiding sparring.':
        'ในสัปดาห์ชกควรเลี่ยงการซ้อมชก',
    'Fuel signals need attention before high-intensity contact.':
        'ควรใส่ใจสัญญาณด้านพลังงานก่อนซ้อมปะทะหนัก',
    'An external plan was self-reported. This app cannot verify it or decide when sparring is safe.':
        'มีการรายงานแผนจากผู้เชี่ยวชาญด้วยตนเอง แอพไม่สามารถตรวจสอบหรือระบุได้ว่าซ้อมชกได้อย่างปลอดภัยเมื่อใด',
    'Shoulder, arm, neck or back pain after training can limit safe defence and punching.':
        'อาการปวดไหล่ แขน คอ หรือหลังหลังซ้อมอาจกระทบการป้องกันตัวและการชกอย่างปลอดภัย',
    'Hydration or weight trend needs attention before intense work.':
        'ควรตรวจแนวโน้มการดื่มน้ำหรือน้ำหนักก่อนซ้อมหนัก',
    'Sleep and heart signals need recovery before intense work.':
        'สัญญาณด้านการนอนและหัวใจบ่งชี้ว่าควรฟื้นตัวก่อนซ้อมหนัก',
    'No head-impact warning is reported in the available data. Follow your coach and safety checks.':
        'ข้อมูลที่มีไม่พบคำเตือนเรื่องการกระแทกศีรษะ ให้ทำตามโค้ชและตรวจความปลอดภัยเสมอ',
    'Upper-body pain after training makes further punching load a poor choice today.':
        'อาการปวดช่วงบนหลังซ้อมทำให้การชกเพิ่มวันนี้ไม่เหมาะสม',
    'Hydration or weight trend needs attention before hard conditioning.':
        'ควรตรวจแนวโน้มการดื่มน้ำหรือน้ำหนักก่อนฝึกความทนทานหนัก',
    'Hydration or weight trend needs attention before hard technical work.':
        'ควรตรวจแนวโน้มการดื่มน้ำหรือน้ำหนักก่อนซ้อมเทคนิคหนัก',
    'Hydration or weight trend needs attention before heavy lifting.':
        'ควรตรวจแนวโน้มการดื่มน้ำหรือน้ำหนักก่อนยกน้ำหนักหนัก',
    'A long hard conditioning session was logged recently; skip another interval session.':
        'เพิ่งบันทึกการฝึกความทนทานหนักและนาน ควรงดอินเทอร์วัลอีกครั้ง',
    'A long hard technical session was logged recently.':
        'เพิ่งบันทึกการซ้อมเทคนิคหนักและนาน',
    'A long or hard strength session was logged recently.':
        'เพิ่งบันทึกการฝึกกำลังที่นานหรือหนัก',
    'No specific conditioning restriction appears in the available data.':
        'ข้อมูลที่มีไม่พบข้อจำกัดเฉพาะสำหรับการฝึกความทนทาน',
    'No specific strength-load restriction appears in the available data.':
        'ข้อมูลที่มีไม่พบข้อจำกัดเฉพาะสำหรับการฝึกกำลัง',
    'No specific technical-load restriction appears in the available data.':
        'ข้อมูลที่มีไม่พบข้อจำกัดเฉพาะสำหรับการซ้อมเทคนิค',
    'Soreness was reported; avoid loading the sore area.':
        'มีรายงานอาการเมื่อย ควรเลี่ยงการลงแรงบริเวณนั้น',
    'Pain in the legs or back was reported; avoid running and intervals that aggravate it.':
        'มีรายงานอาการปวดขาหรือหลัง ควรเลี่ยงการวิ่งและอินเทอร์วัลที่ทำให้อาการแย่ลง',
    'Body soreness is present today. Avoid painful movement.':
        'วันนี้มีอาการเมื่อย ควรเลี่ยงการเคลื่อนไหวที่ทำให้ปวด',
    'Sleep and heart signals call for a lighter session.':
        'สัญญาณด้านการนอนและหัวใจบ่งชี้ว่าควรซ้อมเบาลง',
    'Sleep and heart signals call for reduced intensity.':
        'สัญญาณด้านการนอนและหัวใจบ่งชี้ว่าควรลดความหนัก',
    'affected area': 'บริเวณที่มีอาการ',
    'Pads and bag work with upper-body pain': 'ซ้อมเป้าและกระสอบขณะปวดช่วงบน',
    'Sparring with upper-body pain': 'ซ้อมชกขณะปวดช่วงบน',
    '14 days ago': '14 วันก่อน',
    '28-day head contact': 'การกระแทกศีรษะใน 28 วัน',
    '4 in · 8 out · nose only': 'หายใจเข้า 4 · ออก 8 · ทางจมูกเท่านั้น',
    'A single morning can show a change, not what caused it. Keep checking in to learn your pattern.':
        'ข้อมูลเช้าวันเดียวบอกการเปลี่ยนแปลงได้ แต่ยังบอกสาเหตุไม่ได้ เช็กอินต่อเนื่องเพื่อดูรูปแบบของคุณ',
    'FightCamp data is synthetic for the prototype. No undocumented API or real connection is used. Punch count informs Power & Speed when a personal baseline is available.':
        'ข้อมูล FightCamp เป็นข้อมูลจำลองสำหรับต้นแบบ ไม่มีการเชื่อมต่อจริงหรือใช้ API ที่ไม่ได้รับอนุญาต จำนวนหมัดจะช่วยประเมินพลังและความเร็วเมื่อมีค่าพื้นฐานส่วนบุคคล',
    'Last 14 days': '14 วันที่ผ่านมา',
    'Next Morning': 'เช้าวันถัดไป',
    'Record this only if a qualified healthcare professional evaluated this concern and explicitly gave you a return-to-contact plan. This is your self-report; the app cannot verify the advice or provide medical clearance. Head-contact training remains restricted today.':
        'บันทึกเฉพาะเมื่อบุคลากรทางการแพทย์ที่มีคุณสมบัติเหมาะสมประเมินแล้วและให้แผนกลับไปซ้อมแบบมีการกระแทกอย่างชัดเจน ข้อมูลนี้เป็นการรายงานด้วยตนเอง แอพไม่สามารถยืนยันคำแนะนำหรือรับรองความพร้อมทางการแพทย์ได้ วันนี้ยังต้องงดการซ้อมที่เสี่ยงต่อการกระแทกศีรษะ',
    'punches': 'หมัด',
    '●  TODAY': '●  วันนี้',
    'A previous head-impact concern is still flagged. Answer today’s symptoms honestly; choosing No does not remove the safety restriction. Review the Brain screen after this check-in.':
        'ยังมีการแจ้งเตือนเรื่องการกระแทกศีรษะก่อนหน้า กรุณาตอบอาการวันนี้ตามจริง การเลือก “ไม่” ไม่ได้ยกเลิกข้อจำกัดด้านความปลอดภัย ดูหน้าสมองหลังเช็กอิน',
    'Optional estimate. Confirm every entry yourself.':
        'ค่าประมาณที่ไม่บังคับ กรุณายืนยันข้อมูลทุกช่องด้วยตนเอง',
    'Preset estimate × servings. A photo is not analyzed automatically. Review and correct every number before saving.':
        'ค่าประมาณต่อหนึ่งหน่วย × จำนวนที่กิน รูปภาพไม่ได้ถูกวิเคราะห์อัตโนมัติ กรุณาตรวจและแก้ตัวเลขก่อนบันทึก',
    'Today so far · user-confirmed estimates':
        'วันนี้จนถึงตอนนี้ · ค่าประมาณที่ผู้ใช้ยืนยัน',
    'kg': 'กก.',
    'Apple Health values appear after you grant access and matching records are available. FightCamp punch data is a labelled prototype source.':
        'ข้อมูล Apple Health จะแสดงเมื่อคุณอนุญาตและมีข้อมูลที่ตรงกัน ข้อมูลหมัด FightCamp เป็นแหล่งข้อมูลต้นแบบที่ระบุชัดเจน',
    'Enter the backup passphrase and choose a local passphrase for this device. Both must be at least 8 characters.':
        'กรอกรหัสผ่านของไฟล์สำรองและตั้งรหัสผ่านในเครื่องนี้ ทั้งสองรหัสต้องยาวอย่างน้อย 8 ตัวอักษร',
    'Live Apple Health reading requires an iPhone. You can continue with unavailable metrics.':
        'การอ่าน Apple Health จริงต้องใช้ iPhone คุณสามารถดำเนินการต่อได้แม้ยังไม่มีข้อมูลสุขภาพ',
    'Morning weight  ·  Urine colour  ·  Mood  ·  Boxing training details':
        'น้ำหนักตอนเช้า  ·  สีปัสสาวะ  ·  อารมณ์  ·  รายละเอียดการซ้อมมวย',
    'On iPhone, allow read-only Apple Health access. Sources with readable records appear automatically, including watches and rings that write to Apple Health. Missing metrics stay Unavailable.':
        'บน iPhone ให้อนุญาตการอ่านข้อมูล Apple Health แหล่งข้อมูลที่มีรายการอ่านได้จะแสดงอัตโนมัติ รวมถึงนาฬิกาและแหวนที่ส่งข้อมูลไปยัง Apple Health ค่าที่ไม่มีข้อมูลจะแสดงว่าไม่มีข้อมูล',
    'Set up your athlete profile to begin learning your baseline.':
        'ตั้งโปรไฟล์นักกีฬาเพื่อเริ่มเรียนรู้ค่าพื้นฐานของคุณ',
    'Unlock your locally encrypted athlete data.':
        'ปลดล็อกข้อมูลนักกีฬาที่เข้ารหัสไว้ในเครื่อง',
    'Your personal baseline improves as data arrives. Missing metrics stay Unavailable.':
        'ค่าพื้นฐานส่วนบุคคลจะดีขึ้นเมื่อมีข้อมูลเพิ่ม ค่าที่ขาดไปจะแสดงว่าไม่มีข้อมูล',
    'Backups are encrypted files you save yourself. Nothing is uploaded by the app.':
        'ไฟล์สำรองถูกเข้ารหัสและคุณเป็นผู้จัดเก็บเอง แอพไม่อัปโหลดข้อมูล',
    'Last sync returned no records with an identifiable source. Saved history is unchanged; check Apple Health data and read access.':
        'การซิงก์ล่าสุดไม่พบข้อมูลที่ระบุแหล่งที่มาได้ ประวัติที่บันทึกไว้ไม่เปลี่ยนแปลง กรุณาตรวจข้อมูลและสิทธิ์การอ่านใน Apple Health',
    'Recovery tracking continues. Add a fight date when your next bout is confirmed.':
        'การติดตามการฟื้นตัวยังดำเนินต่อไป เพิ่มวันชกเมื่อยืนยันไฟต์ครั้งถัดไปแล้ว',
    'Sleep & Heart · recent days': 'การนอนและหัวใจ · วันที่ผ่านมา',
    'This permanently deletes the local athlete data in this app.':
        'การดำเนินการนี้จะลบข้อมูลนักกีฬาในเครื่องอย่างถาวร',
    'To revoke Apple Health read permission, use the iPhone Health app. Disconnect here clears locally imported records.':
        'หากต้องการเพิกถอนสิทธิ์อ่าน Apple Health ให้ใช้แอพ Health บน iPhone การยกเลิกการเชื่อมต่อที่นี่จะลบข้อมูลที่นำเข้าในเครื่อง',
    'Use at least 8 characters. Keep this passphrase: the backup cannot be opened without it.':
        'ใช้อย่างน้อย 8 ตัวอักษร และเก็บรหัสผ่านนี้ไว้ เพราะจะเปิดไฟล์สำรองไม่ได้หากไม่มีรหัส',
    'Weight data supports safety monitoring. Seek qualified support for weight or hydration concerns.':
        'ข้อมูลน้ำหนักใช้เพื่อติดตามความปลอดภัย หากกังวลเรื่องน้ำหนักหรือภาวะขาดน้ำ ควรปรึกษาผู้เชี่ยวชาญ',
  };

  static const Map<String, String> _inlineThai = {
    'No fight scheduled': 'ยังไม่กำหนดวันชก',
    'No target weight set': 'ยังไม่ตั้งน้ำหนักเป้าหมาย',
    'days out': 'วันก่อนชก',
    'Current phase:': 'ช่วงแคมป์ปัจจุบัน:',
    'Fight:': 'วันชก:',
    'Target:': 'เป้าหมาย:',
    'Current weight:': 'น้ำหนักปัจจุบัน:',
    'Height:': 'ส่วนสูง:',
    'Health:': 'สุขภาพ:',
    'Last scheduled date:': 'วันชกที่เคยกำหนด:',
    'recorded days': 'วันที่บันทึก',
    'Monitoring only': 'ใช้ติดตามเท่านั้น',
    'assessments recorded': 'การประเมินที่บันทึก',
    'sessions in 28 days': 'ครั้งใน 28 วัน',
    'sessions': 'ครั้ง',
    'rounds': 'ยก',
    'actions completed': 'กิจกรรมที่ทำแล้ว',
    'No data': 'ไม่มีข้อมูล',
    'Unavailable': 'ไม่มีข้อมูล',
    'Learning baseline': 'กำลังเรียนรู้ค่าพื้นฐาน',
    'Baseline': 'ค่าพื้นฐาน',
    'Latest available': 'ข้อมูลล่าสุดที่มี',
    'SAFE': 'ปลอดภัย',
    'SAFETY': 'ความปลอดภัย',
  };
}

/// Drop-in text widget for the existing mobile screens. It preserves styling
/// and translates its string when the user chooses Thai in Settings.
class Text extends material.StatelessWidget {
  const Text(this.data,
      {super.key,
      this.style,
      this.textAlign,
      this.textDirection,
      this.maxLines,
      this.overflow,
      this.softWrap,
      this.semanticsLabel,
      this.textScaler});

  final String data;
  final material.TextStyle? style;
  final material.TextAlign? textAlign;
  final material.TextDirection? textDirection;
  final int? maxLines;
  final material.TextOverflow? overflow;
  final bool? softWrap;
  final String? semanticsLabel;
  final material.TextScaler? textScaler;

  @override
  material.Widget build(material.BuildContext context) => material.Text(
        AppCopy.of(context, data),
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        semanticsLabel: semanticsLabel,
        textScaler: textScaler,
      );
}
