import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});
  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  static const key = 'flutter_diary_entries';
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF8A8A8A);
  static const line = Color(0xFFECECEC);
  final picker = ImagePicker();
  List<_Entry> entries = [];
  bool loading = true;
  String tab = 'long', owner = 'me';

  List<_Entry> get longs => _sorted('long', owner);
  List<_Entry> get notes => _sorted('note', owner);
  List<_Entry> get polas => entries.where((e) => e.type == 'polaroid').toList()..sort((a,b)=>b.time.compareTo(a.time));
  List<_Entry> _sorted(String type, String who) => entries.where((e)=>e.type==type&&e.owner==who).toList()..sort((a,b)=>b.time.compareTo(a.time));

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(key);
    final list = <_Entry>[];
    if (raw != null) {
      try { for (final x in jsonDecode(raw) as List) { if (x is Map) list.add(_Entry.fromMap(x)); } } catch (_) {}
    }
    if (!mounted) return;
    setState(() { entries = list; loading = false; });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, jsonEncode(entries.map((e)=>e.toMap()).toList()));
  }

  Future<void> _upsert(_Entry e) async {
    setState(() {
      final i = entries.indexWhere((x)=>x.id==e.id);
      if (i < 0) { entries.insert(0,e); } else { entries[i]=e; }
    });
    await _save();
  }

  Future<void> _delete(_Entry e) async {
    final ok = await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('删除这条记录？'), content:const Text('删除后无法恢复。'),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('取消')),TextButton(onPressed:()=>Navigator.pop(c,true),child:const Text('删除'))]));
    if (ok != true) return;
    setState(()=>entries.removeWhere((x)=>x.id==e.id)); await _save();
  }

  Future<void> _edit([_Entry? entry, String type='long']) async {
    final result = await Navigator.push<_Entry>(context,MaterialPageRoute(builder:(_)=>_Editor(entry:entry,type:entry?.type??type)));
    if (result != null) await _upsert(result);
  }

  Future<String> _persistPhoto(XFile x) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/mio_diary_photos');
    if (!await folder.exists()) await folder.create(recursive:true);
    final ext = x.path.contains('.') ? x.path.substring(x.path.lastIndexOf('.')) : '.jpg';
    final path = '${folder.path}/${DateTime.now().microsecondsSinceEpoch}${ext}';
    return (await File(x.path).copy(path)).path;
  }

  Future<void> _addPolaroid(String who) async {
    final source = await showModalBottomSheet<ImageSource>(context:context,backgroundColor:Colors.white,builder:(c)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
      ListTile(leading:const Icon(Icons.photo_library_outlined),title:const Text('从相册选择'),onTap:()=>Navigator.pop(c,ImageSource.gallery)),
      ListTile(leading:const Icon(Icons.photo_camera_outlined),title:const Text('拍一张照片'),onTap:()=>Navigator.pop(c,ImageSource.camera)),
    ])));
    if (source==null) return;
    final x = await picker.pickImage(source:source,imageQuality:88,maxWidth:1800);
    if (x==null) return;
    final path = await _persistPhoto(x);
    if (!mounted) return;
    final caption = TextEditingController();
    final ok = await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('给这张拍立得写一句话'),
      content:TextField(controller:caption,maxLength:24,decoration:const InputDecoration(hintText:'留下一句小小的注释')),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('取消')),TextButton(onPressed:()=>Navigator.pop(c,true),child:const Text('打印'))]));
    if (ok==true) {
      final now=DateTime.now(), day=DateTime(now.year,now.month,now.day);
      setState(()=>entries.removeWhere((e)=>e.type=='polaroid'&&e.owner==who&&e.date.year==day.year&&e.date.month==day.month&&e.date.day==day.day));
      await _upsert(_Entry(id:now.microsecondsSinceEpoch.toString(),type:'polaroid',owner:who,title:'',body:caption.text.trim(),date:day,time:now,image:path));
    }
    caption.dispose();
  }

  String _date(DateTime d)=>'${d.year}.${d.month}.${d.day.toString().padLeft(2,'0')}';
  String _clock(DateTime d)=>'${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  Widget _ownerChip(String id,String label) {
    final on=owner==id;
    return GestureDetector(onTap:()=>setState(()=>owner=id),child:AnimatedContainer(duration:const Duration(milliseconds:160),
      padding:const EdgeInsets.fromLTRB(4,4,13,4),
      decoration:BoxDecoration(color:on?ink:Colors.white,border:Border.all(color:on?ink:line),borderRadius:BorderRadius.circular(30)),
      child:Row(children:[CircleAvatar(radius:13,backgroundColor:on?Colors.white:const Color(0xFFF1F1F1),child:Text(id=='me'?'我':'T',style:TextStyle(fontSize:11,color:on?ink:muted))),const SizedBox(width:7),Text(label,style:TextStyle(fontSize:12,color:on?Colors.white:muted))])));
  }

  Widget _profile() => Container(
    decoration:BoxDecoration(border:Border.all(color:line),borderRadius:BorderRadius.circular(14)),
    child:Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,16,16,13),child:Row(children:[
        CircleAvatar(radius:24,backgroundColor:const Color(0xFFF1F1F1),child:Text(owner=='me'?'我':'T',style:const TextStyle(fontSize:18,color:ink))),
        const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(owner=='me'?'我':'TA',style:const TextStyle(fontSize:15,fontWeight:FontWeight.w600)),
          Text(owner=='me'?'@my-diary':'@your-person',style:const TextStyle(fontSize:11,color:muted)),
        ])),const Icon(Icons.more_horiz,color:muted)
      ])),
      const Padding(padding:EdgeInsets.fromLTRB(16,0,16,13),child:Align(alignment:Alignment.centerLeft,child:Text('点这里写一句装饰文案',style:TextStyle(fontSize:13,color:muted)))),
      const Divider(height:1,color:line),
      Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:11),child:Row(children:[
        Text('${longs.length+notes.length}',style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600)),
        const SizedBox(width:5),const Text('篇记录',style:TextStyle(fontSize:11,color:muted)),
        const Spacer(),Text('${DateTime.now().year}',style:const TextStyle(fontSize:11,color:muted))
      ]))
    ]));

  Widget _tabs() {
    final data=[('long','长日记',longs.length),('pola','拍立得',polas.length),('note','留言板',notes.length)];
    return Container(margin:const EdgeInsets.only(top:18,bottom:14),decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:line))),
      child:Row(children:data.map((v){
        final on=tab==v.$1;
        return Expanded(child:GestureDetector(behavior:HitTestBehavior.opaque,onTap:()=>setState(()=>tab=v.$1),
          child:Container(padding:const EdgeInsets.fromLTRB(2,11,2,12),
            decoration:BoxDecoration(border:Border(bottom:BorderSide(color:on?ink:Colors.transparent,width:2))),
            child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
              Text(v.$2,style:TextStyle(fontSize:14,color:on?ink:muted,fontWeight:on?FontWeight.w600:FontWeight.w400)),
              const SizedBox(width:5),Text('${v.$3}',style:const TextStyle(fontSize:10,color:muted))
            ]))));
      }).toList()));
  }

  Widget _button(String text,VoidCallback action,{bool filled=false})=>Material(color:filled?ink:Colors.white,borderRadius:BorderRadius.circular(30),
    child:InkWell(onTap:action,borderRadius:BorderRadius.circular(30),child:Container(
      padding:const EdgeInsets.symmetric(horizontal:17,vertical:9),
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(30),border:Border.all(color:filled?ink:line)),
      child:Text(text,style:TextStyle(fontSize:12,fontWeight:FontWeight.w500,color:filled?Colors.white:ink)))));

  Widget _longList() {
    if(longs.isEmpty)return _empty('还没有日记','把今天想记住的事写下来吧。');
    return ListView.builder(padding:const EdgeInsets.only(bottom:24),itemCount:longs.length,itemBuilder:(c,i){
      final e=longs[i];
      return Dismissible(key:ValueKey(e.id),direction:DismissDirection.endToStart,
        background:Container(alignment:Alignment.centerRight,padding:const EdgeInsets.only(right:22),color:const Color(0xFFE5484D),child:const Icon(Icons.delete_outline,color:Colors.white)),
        confirmDismiss:(_)async{await _delete(e);return false;},
        child:InkWell(onTap:()=>_reader(e),child:Container(padding:const EdgeInsets.symmetric(vertical:16,horizontal:2),
          decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:line))),
          child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
            SizedBox(width:44,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('${e.date.day}',style:const TextStyle(fontSize:26,height:1.05,fontWeight:FontWeight.w500)),
              const SizedBox(height:3),Text('${e.date.year}.${e.date.month}',style:const TextStyle(fontSize:10,color:muted))
            ])),
            const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(e.title.isEmpty?'无标题':e.title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600)),
              const SizedBox(height:6),Text(e.body,maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12.5,height:1.7,color:Color(0xFF777777)))
            ]))
          ]))));
    });
  }

  void _reader(_Entry e) => Navigator.push(context,MaterialPageRoute(builder:(_)=>_Reader(entry:e,
    onEdit:()async{Navigator.pop(context);await _edit(e);},
    onDelete:()async{Navigator.pop(context);await _delete(e);},
    onComment:(v)async{e.comment=v;await _upsert(e);})));

  Widget _noteBoard() {
    if(notes.isEmpty)return _empty('留言板还是空的','写下一句随手的话，留给对方。');
    return ListView.separated(padding:const EdgeInsets.only(bottom:24),itemCount:notes.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(c,i){
      final e=notes[i];
      return Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(border:Border.all(color:line),borderRadius:BorderRadius.circular(14)),
        child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          CircleAvatar(radius:17,backgroundColor:const Color(0xFFF0F0F0),child:Text(e.owner=='me'?'我':'T',style:const TextStyle(fontSize:12,color:ink))),
          const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[Text(e.owner=='me'?'我':'TA',style:const TextStyle(fontSize:13,fontWeight:FontWeight.w600)),
              const SizedBox(width:8),Text('${_date(e.time)}  ${_clock(e.time)}',style:const TextStyle(fontSize:10.5,color:muted)),
              const Spacer(),GestureDetector(onTap:()=>_delete(e),child:const Icon(Icons.close,size:16,color:muted))]),
            const SizedBox(height:7),Text(e.body,style:const TextStyle(fontSize:14,height:1.7,color:ink))
          ]))
        ]));
    });
  }

  Widget _empty(String title,String sub)=>Center(child:Padding(padding:const EdgeInsets.all(30),child:Column(mainAxisSize:MainAxisSize.min,children:[
    const Icon(Icons.menu_book_outlined,size:30,color:Color(0xFFBBBBBB)),const SizedBox(height:12),
    Text(title,style:const TextStyle(fontSize:13,color:muted)),const SizedBox(height:6),
    Text(sub,textAlign:TextAlign.center,style:const TextStyle(fontSize:11,color:muted))
  ])));

  _Entry? _today(String who) {
    final n=DateTime.now();
    for(final e in polas){if(e.owner==who&&e.date.year==n.year&&e.date.month==n.month&&e.date.day==n.day)return e;}
    return null;
  }

  Widget _photoCard(_Entry e,{bool small=false}) {
    final f=File(e.image);
    return Container(width:double.infinity,padding:EdgeInsets.all(small?5:10),
      decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(3),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.10),blurRadius:small?8:16,offset:const Offset(0,5))]),
      child:Column(children:[
        AspectRatio(aspectRatio:1,child:ClipRect(child:f.existsSync()?Image.file(f,fit:BoxFit.cover,width:double.infinity,errorBuilder:(_,__,___)=>_photoPlaceholder()):_photoPlaceholder())),
        SizedBox(height:small?5:9),SizedBox(height:small?17:24,child:Text(e.body,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:small?9:12,color:ink))),
        if(!small)Align(alignment:Alignment.centerRight,child:Text('${e.date.month}.${e.date.day}',style:const TextStyle(fontSize:9,color:muted)))
      ]));
  }
  Widget _photoPlaceholder()=>Container(color:const Color(0xFFE6E6E6),child:const Center(child:Icon(Icons.image_outlined,color:Colors.white)));

  Widget _polaroids() {
    Widget slot(String who,int tilt) {
      final e=_today(who);
      return Expanded(child:Column(children:[
        Row(mainAxisAlignment:MainAxisAlignment.center,children:[CircleAvatar(radius:11,backgroundColor:const Color(0xFFF0F0F0),child:Text(who=='me'?'我':'T',style:const TextStyle(fontSize:9,color:ink))),const SizedBox(width:6),Text(who=='me'?'我':'TA',style:const TextStyle(fontSize:12,color:muted))]),
        const SizedBox(height:12),
        GestureDetector(onTap:()=>e==null?_addPolaroid(who):_showPolaroid(e),child:Transform.rotate(angle:tilt==0?-.035:.035,child:e==null
          ?AspectRatio(aspectRatio:190/236,child:Container(decoration:BoxDecoration(border:Border.all(color:line,width:1.5),borderRadius:BorderRadius.circular(3)),child:const Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.add_photo_alternate_outlined,size:25,color:muted),SizedBox(height:8),Text('今天还没有',style:TextStyle(fontSize:11,color:muted))])))
          :_photoCard(e))),
        const SizedBox(height:12),_button(e==null?(who=='me'?'上传并打印':'让 TA 自己选'):(who=='me'?'重新打印':'让 TA 重新选'),()=>_addPolaroid(who),filled:e==null)
      ]));
    }
    return ListView(padding:const EdgeInsets.only(bottom:24),children:[
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[slot('me',0),const SizedBox(width:16),slot('ta',1)]),
      Padding(padding:const EdgeInsets.symmetric(vertical:18),child:Text('${_date(DateTime.now())}  ·  今日拍立得',textAlign:TextAlign.center,style:const TextStyle(fontSize:11,color:muted))),
      if(polas.isNotEmpty)...[
        const Padding(padding:EdgeInsets.only(bottom:11),child:Text('相册',style:TextStyle(fontSize:12,letterSpacing:1.8,color:muted))),
        GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:polas.length,
          gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:11,mainAxisSpacing:14,childAspectRatio:.78),
          itemBuilder:(c,i)=>GestureDetector(onTap:()=>_showPolaroid(polas[i]),child:_photoCard(polas[i],small:true)))
      ]
    ]);
  }

  Future<void> _showPolaroid(_Entry e) async {
    await showDialog<void>(context:context,builder:(c)=>Dialog(backgroundColor:Colors.transparent,child:Column(mainAxisSize:MainAxisSize.min,children:[
      _photoCard(e),const SizedBox(height:14),TextButton(onPressed:(){Navigator.pop(c);_delete(e);},child:const Text('删除这张拍立得',style:TextStyle(color:Colors.white)))
    ])));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor:Colors.white,
    appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.transparent,elevation:0,
      leading:IconButton(onPressed:()=>context.pop(),icon:const Icon(Icons.arrow_back_ios_new_rounded,size:18,color:ink)),
      title:const Text('日记',style:TextStyle(fontSize:16,fontWeight:FontWeight.w600,color:ink)),centerTitle:true,
      actions:[if(tab!='pola')IconButton(onPressed:()=>_edit(null,tab=='note'?'note':'long'),icon:const Icon(Icons.add,color:ink)),const SizedBox(width:4)]),
    body:SafeArea(top:false,child:loading?const Center(child:CircularProgressIndicator(strokeWidth:1.5,color:ink)):Column(children:[
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(18,8,18,0),children:[
        SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[_ownerChip('me','我'),const SizedBox(width:6),_ownerChip('ta','TA')])),
        const SizedBox(height:14),_profile(),_tabs(),
        if(tab!='pola')Padding(padding:const EdgeInsets.only(bottom:12),child:Row(children:[
          _button(tab=='note'?'写留言':'写日记',()=>_edit(null,tab=='note'?'note':'long'),filled:true),
          if(tab=='long')... [const SizedBox(width:8),_button('搜索',_search)]
        ])),
        SizedBox(height:MediaQuery.of(context).size.height*.58,child:tab=='long'?_longList():tab=='note'?_noteBoard():_polaroids())
      ]))
    ]))
  );

  Future<void> _search() async {
    final c=TextEditingController();
    final v=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:const Text('搜索日记'),content:TextField(controller:c,autofocus:true,decoration:const InputDecoration(hintText:'输入标题或正文')),actions:[
      TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('取消')),TextButton(onPressed:()=>Navigator.pop(ctx,c.text.trim()),child:const Text('搜索'))
    ]));
    if(v==null||v.isEmpty){c.dispose();return;}
    final found=longs.where((e)=>e.title.contains(v)||e.body.contains(v)).toList();
    c.dispose();
    if(found.isEmpty){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('没有找到相关日记')));}else if(mounted){_reader(found.first);}
  }
}

class _Editor extends StatefulWidget {
  const _Editor({this.entry,required this.type});
  final _Entry? entry; final String type;
  @override State<_Editor> createState()=>_EditorState();
}
class _EditorState extends State<_Editor> {
  late final TextEditingController title,body;
  late DateTime date;
  @override void initState(){super.initState();title=TextEditingController(text:widget.entry?.title??'');body=TextEditingController(text:widget.entry?.body??'');date=widget.entry?.date??DateTime.now();}
  @override void dispose(){title.dispose();body.dispose();super.dispose();}
  Future<void> _pickDate() async {final d=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime.now().add(const Duration(days:365)));if(d!=null)setState(()=>date=d);}
  void _save(){
    final text=body.text.trim();if(text.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('正文不能为空')));return;}
    final now=DateTime.now();
    Navigator.pop(context,_Entry(id:widget.entry?.id??now.microsecondsSinceEpoch.toString(),type:widget.type,owner:widget.entry?.owner??'me',title:title.text.trim(),body:text,date:date,time:now,image:widget.entry?.image??'',comment:widget.entry?.comment??''));
  }
  @override Widget build(BuildContext context){
    final note=widget.type=='note';
    return Scaffold(backgroundColor:Colors.white,appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.transparent,elevation:0,
      leading:TextButton(onPressed:()=>Navigator.pop(context),child:const Text('取消',style:TextStyle(color:Color(0xFF777777)))),
      title:Text(widget.entry==null?(note?'写留言':'写日记'):'编辑',style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:Color(0xFF111111))),centerTitle:true,
      actions:[TextButton(onPressed:_save,child:const Text('完成',style:TextStyle(color:Colors.black,fontWeight:FontWeight.w700))),const SizedBox(width:8)]),
      body:SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(22,12,22,32),children:[
        if(!note)...[
          Row(children:[const Icon(Icons.schedule,size:14,color:Color(0xFF999999)),const SizedBox(width:7),Text('${date.year}.${date.month}.${date.day}',style:const TextStyle(fontSize:11,color:Color(0xFF777777))),const Spacer(),TextButton(onPressed:_pickDate,child:const Text('更改日期',style:TextStyle(fontSize:11,color:Colors.black)))]),
          const SizedBox(height:13),TextField(controller:title,maxLength:40,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w600),decoration:const InputDecoration(counterText:'',hintText:'标题',border:InputBorder.none,hintStyle:TextStyle(color:Color(0xFFBBBBBB),fontWeight:FontWeight.w400))),
          const Divider(height:1,color:Color(0xFFECECEC))
        ],
        const SizedBox(height:14),TextField(controller:body,autofocus:true,minLines:note?4:12,maxLines:null,keyboardType:TextInputType.multiline,
          style:const TextStyle(fontSize:15,height:1.95,color:Color(0xFF222222)),
          decoration:InputDecoration(hintText:note?'留下一句想说的话…':'写点什么…',border:InputBorder.none,hintStyle:const TextStyle(color:Color(0xFFBBBBBB),fontSize:14)))
      ]))
    );
  }
}

class _Reader extends StatefulWidget {
  const _Reader({required this.entry,required this.onEdit,required this.onDelete,required this.onComment});
  final _Entry entry;final VoidCallback onEdit,onDelete;final ValueChanged<String> onComment;
  @override State<_Reader> createState()=>_ReaderState();
}
class _ReaderState extends State<_Reader>{
  late final TextEditingController comment;
  @override void initState(){super.initState();comment=TextEditingController(text:widget.entry.comment);}
  @override void dispose(){comment.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final e=widget.entry;
    return Scaffold(backgroundColor:Colors.white,appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.transparent,elevation:0,
      leading:IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.arrow_back_ios_new,size:18)),
      title:const Text('日记',style:TextStyle(fontSize:14,fontWeight:FontWeight.w600)),centerTitle:true,
      actions:[IconButton(onPressed:widget.onEdit,icon:const Icon(Icons.edit_outlined,size:19)),PopupMenuButton<String>(onSelected:(v){if(v=='delete')widget.onDelete();},itemBuilder:(_)=>const[PopupMenuItem(value:'delete',child:Text('删除'))])]),
      body:SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(22,12,22,30),children:[
        Row(children:[const CircleAvatar(radius:18,backgroundColor:Color(0xFFF0F0F0),child:Text('我',style:TextStyle(color:Color(0xFF111111),fontSize:12))),const SizedBox(width:10),const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('我',style:TextStyle(fontSize:14,fontWeight:FontWeight.w600)),Text('Mio Diary',style:TextStyle(fontSize:10,color:Color(0xFF999999)))]),const Spacer(),Text('${e.date.year}/${e.date.month}/${e.date.day}',style:const TextStyle(fontSize:10,color:Color(0xFF999999)))]),
        const SizedBox(height:26),if(e.title.isNotEmpty)Text(e.title,style:const TextStyle(fontSize:23,height:1.4,fontWeight:FontWeight.w600)),
        if(e.title.isNotEmpty)const SizedBox(height:18),Text(e.body,style:const TextStyle(fontSize:15,height:2,color:Color(0xFF222222))),
        const SizedBox(height:24),const Divider(color:Color(0xFFECECEC)),const SizedBox(height:14),
        const Text('留言',style:TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:Color(0xFF777777))),const SizedBox(height:10),
        TextField(controller:comment,minLines:1,maxLines:4,decoration:InputDecoration(hintText:'回复这篇日记…',filled:true,fillColor:const Color(0xFFF7F7F7),border:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide.none),
          suffixIcon:IconButton(icon:const Icon(Icons.send_rounded,size:18),onPressed:(){widget.onComment(comment.text.trim());FocusScope.of(context).unfocus();}))),
        if(e.comment.isNotEmpty)Padding(padding:const EdgeInsets.only(top:12),child:Text(e.comment,style:const TextStyle(fontSize:13,height:1.7)))
      ]))
    );
  }
}

class _Entry {
  _Entry({required this.id,required this.type,required this.owner,required this.title,required this.body,required this.date,required this.time,this.image='',this.comment=''});
  final String id,type,owner,title,body,image;
  final DateTime date,time;
  String comment;
  Map<String,dynamic> toMap()=>{'id':id,'type':type,'owner':owner,'title':title,'body':body,'date':date.toIso8601String(),'time':time.toIso8601String(),'updatedAt':time.toIso8601String(),'imagePath':image,'image':image,'comment':comment};
  factory _Entry.fromMap(Map m){
    final d=DateTime.tryParse((m['date']??'').toString())??DateTime.now();
    return _Entry(id:(m['id']??DateTime.now().microsecondsSinceEpoch).toString(),type:(m['type']??'long').toString(),owner:(m['owner']??'me').toString(),title:(m['title']??'').toString(),body:(m['body']??'').toString(),date:d,time:DateTime.tryParse((m['time']??m['updatedAt']??'').toString())??d,image:(m['imagePath']??m['image']??'').toString(),comment:(m['comment']??'').toString());
  }
}
