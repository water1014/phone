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
  String _decorText = '';
  bool _liked = false;

  List<_Entry> get longs => _sorted('long', owner);
  List<_Entry> get notes => _sorted('note', owner);
  List<_Entry> get polas => entries.where((e) => e.type == 'polaroid').toList()..sort((a,b)=>b.time.compareTo(a.time));
  List<_Entry> _sorted(String type, String who) => entries.where((e)=>e.type==type&&e.owner==who).toList()..sort((a,b)=>b.time.compareTo(a.time));

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(key);
    final decor = p.getString('mio_diary_decor_text') ?? '';
    final list = <_Entry>[];
    if (raw != null) {
      try { for (final x in jsonDecode(raw) as List) { if (x is Map) list.add(_Entry.fromMap(x)); } } catch (_) {}
    }
    if (!mounted) return;
    setState(() { entries = list; _decorText = decor; loading = false; });
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
    final path = '${folder.path}/${DateTime.now().microsecondsSinceEpoch}$ext';
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
    if (ok==true && mounted) {
      final printed=await _printPolaroid(path,caption.text.trim());
      if(printed==true){
        final now=DateTime.now(), day=DateTime(now.year,now.month,now.day);
        setState(()=>entries.removeWhere((e)=>e.type=='polaroid'&&e.owner==who&&e.date.year==day.year&&e.date.month==day.month&&e.date.day==day.day));
        await _upsert(_Entry(id:now.microsecondsSinceEpoch.toString(),type:'polaroid',owner:who,title:'',body:caption.text.trim(),date:day,time:now,image:path));
      }
    }
    caption.dispose();
  }

  Future<bool?> _printPolaroid(String path,String caption) async {
    var printing=true;
    return showDialog<bool>(context:context,barrierDismissible:false,builder:(dialogContext){
      return StatefulBuilder(builder:(context,setDialogState){
        if(printing){
          Future.delayed(const Duration(milliseconds:2600),(){
            if(dialogContext.mounted){setDialogState(()=>printing=false);}
          });
        }
        final file=File(path);
        return Dialog(
          backgroundColor:Colors.transparent,
          insetPadding:const EdgeInsets.symmetric(horizontal:28),
          child:Container(
            padding:const EdgeInsets.fromLTRB(22,26,22,22),
            decoration:BoxDecoration(color:const Color(0xFFF7F7F7),borderRadius:BorderRadius.circular(24)),
            child:Column(mainAxisSize:MainAxisSize.min,children:[
              AnimatedContainer(duration:const Duration(milliseconds:350),width:210,height:printing?172:210,
                decoration:BoxDecoration(color:const Color(0xFF242424),borderRadius:BorderRadius.circular(34),
                  boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.2),blurRadius:22,offset:const Offset(0,12))]),
                child:Stack(alignment:Alignment.topCenter,children:[
                  Positioned(top:23,left:22,right:22,child:Container(height:17,decoration:BoxDecoration(color:Colors.black,borderRadius:BorderRadius.circular(10)))),
                  Positioned(top:57,right:27,child:Container(width:8,height:8,decoration:BoxDecoration(color:printing?Colors.white:const Color(0xFF8FD6A3),shape:BoxShape.circle))),
                  AnimatedPositioned(duration:const Duration(milliseconds:850),curve:Curves.easeOutCubic,
                    top:printing?54:82,left:35,right:35,
                    child:AnimatedOpacity(duration:const Duration(milliseconds:500),opacity:printing ? 0.0 : 1.0,
                      child:Container(padding:const EdgeInsets.fromLTRB(6,6,6,0),color:Colors.white,
                        child:Column(mainAxisSize:MainAxisSize.min,children:[
                          AspectRatio(aspectRatio:1,child:file.existsSync()?Image.file(file,fit:BoxFit.cover):const ColoredBox(color:Color(0xFFE6E6E6))),
                          SizedBox(height:printing?0:20,child:Text(caption,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.black,fontSize:10)))
                        ])))
                  )
                ])
              ),
              const SizedBox(height:22),
              Text(printing?'正在打印今天的拍立得…':'打印完成',style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:Color(0xFF222222))),
              const SizedBox(height:6),
              Text(printing?'照片正在慢慢显影':'把这张照片收进你们的相册吧',style:const TextStyle(fontSize:11,color:Color(0xFF888888))),
              const SizedBox(height:18),
              if(!printing)SizedBox(width:double.infinity,child:ElevatedButton(
                style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFF171717),foregroundColor:Colors.white,padding:const EdgeInsets.symmetric(vertical:13)),
                onPressed:()=>Navigator.pop(dialogContext,true),child:const Text('收进相册')))
              else const SizedBox(height:3,child:LinearProgressIndicator(minHeight:2,color:Color(0xFF222222),backgroundColor:Color(0xFFE3E3E3)))
            ])
          )
        );
      });
    });
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

  Widget _profile() {
    final count=longs.length+notes.length;
    final now=DateTime.now();
    final stamp='${now.year}/${now.month}/${now.day}  ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
    return Container(
      decoration:BoxDecoration(color:Colors.white,border:Border.all(color:line),borderRadius:BorderRadius.circular(14)),
      clipBehavior:Clip.antiAlias,
      child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Padding(padding:const EdgeInsets.fromLTRB(14,14,14,0),child:Row(children:[
          CircleAvatar(radius:19,backgroundColor:const Color(0xFFF0F0F0),child:Text(owner=='me'?'我':'T',style:const TextStyle(fontSize:15,color:ink))),
          const SizedBox(width:10),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(owner=='me'?'我':'TA',style:const TextStyle(fontSize:14,fontWeight:FontWeight.w700,color:ink)),
            Text(owner=='me'?'@me':'@companion',style:const TextStyle(fontSize:11.5,color:muted)),
          ])),
          IconButton(visualDensity:VisualDensity.compact,onPressed:_editHeaderText,icon:const Icon(Icons.more_horiz,color:muted))
        ])),
        Padding(padding:const EdgeInsets.fromLTRB(14,9,14,11),child:GestureDetector(
          onTap:_editHeaderText,
          child:Text(_decorText.isEmpty?'点这里写一句装饰文字':_decorText,
            style:TextStyle(fontSize:13,height:1.55,color:_decorText.isEmpty?muted:ink)),
        )),
        Padding(padding:const EdgeInsets.fromLTRB(14,0,14,11),child:Row(children:[
          const Icon(Icons.schedule_rounded,size:13,color:muted),
          const SizedBox(width:5),
          Text(stamp,style:const TextStyle(fontSize:10.5,color:muted)),
          const Spacer(),
          Text('$count 篇记录',style:const TextStyle(fontSize:10.5,color:muted)),
        ])),
        const Divider(height:1,color:line),
        Row(children:[
          Expanded(child:_postAction(Icons.favorite_border_rounded,_liked?'已喜欢':'喜欢',onTap:()=>setState(()=>_liked=!_liked),active:_liked)),
          Container(width:1,height:18,color:line),
          Expanded(child:_postAction(Icons.chat_bubble_outline_rounded,'留言板',onTap:()=>setState(()=>tab='note'))),
          Container(width:1,height:18,color:line),
          Expanded(child:_postAction(Icons.more_horiz_rounded,'装饰文案',onTap:_editHeaderText)),
        ])
      ])
    );
  }

  Widget _postAction(IconData icon,String label,{required VoidCallback onTap,bool active=false})=>InkWell(
    onTap:onTap,child:Padding(padding:const EdgeInsets.symmetric(vertical:11,horizontal:3),
      child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
        Icon(icon,size:16,color:active?ink:muted),const SizedBox(width:5),
        Text(label,style:TextStyle(fontSize:11.5,color:active?ink:muted,fontWeight:active?FontWeight.w600:FontWeight.w400))
      ])));

  Future<void> _editHeaderText() async {
    final controller=TextEditingController(text:_decorText);
    final value=await showDialog<String>(context:context,builder:(context)=>AlertDialog(
      title:const Text('装饰文案'),
      content:TextField(controller:controller,maxLines:3,maxLength:100,decoration:const InputDecoration(hintText:'写一句留在日记主页的话')),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(context),child:const Text('取消')),
        TextButton(onPressed:()=>Navigator.pop(context,controller.text.trim()),child:const Text('保存')),
      ],
    ));
    controller.dispose();
    if(value==null)return;
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString('mio_diary_decor_text',value);
    if(mounted)setState(()=>_decorText=value);
  }

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
      return _SwipeDiaryCard(entry:e,onOpen:()=>_reader(e),onEdit:()=>_edit(e),onDelete:()=>_delete(e));
    });
  }

  void _reader(_Entry e) => Navigator.push(context,MaterialPageRoute(builder:(_)=>_Reader(entry:e,decorText:_decorText,ownerName:owner=='me'?'我':'TA',
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

class _SwipeDiaryCard extends StatefulWidget {
  const _SwipeDiaryCard({required this.entry,required this.onOpen,required this.onEdit,required this.onDelete});
  final _Entry entry;
  final VoidCallback onOpen,onEdit,onDelete;
  @override State<_SwipeDiaryCard> createState()=>_SwipeDiaryCardState();
}
class _SwipeDiaryCardState extends State<_SwipeDiaryCard> {
  double offset=0;
  static const double reveal=136;
  void _settle()=>setState(()=>offset=offset < -reveal/2 ? -reveal : 0);
  @override Widget build(BuildContext context){
    final e=widget.entry;
    final preview=e.displayBody.replaceAll(RegExp(r'\[\[(?:红|蓝)[:：]([\s\S]*?)\]\]'),r'$1');
    return SizedBox(
      height:104,
      child:Stack(
        alignment:Alignment.centerRight,
        children:[
          Positioned.fill(child:Row(mainAxisAlignment:MainAxisAlignment.end,children:[
            SizedBox(width:68,child:Material(color:const Color(0xFFF1F1F1),child:InkWell(
              onTap:(){setState(()=>offset=0);widget.onEdit();},
              child:const Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                Icon(Icons.edit_outlined,size:18),SizedBox(height:4),Text('编辑',style:TextStyle(fontSize:11))
              ]))
            ))),
            SizedBox(width:68,child:Material(color:const Color(0xFFE95B62),child:InkWell(
              onTap:widget.onDelete,
              child:const Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                Icon(Icons.delete_outline,color:Colors.white,size:18),SizedBox(height:4),Text('删除',style:TextStyle(fontSize:11,color:Colors.white))
              ]))
            )))
          ])),
          AnimatedContainer(
            duration:const Duration(milliseconds:180),
            curve:Curves.easeOut,
            transform:Matrix4.translationValues(offset,0,0),
            color:Colors.white,
            child:GestureDetector(
              onHorizontalDragUpdate:(d)=>setState(()=>offset=(offset+d.delta.dx).clamp(-reveal,0).toDouble()),
              onHorizontalDragEnd:(_)=>_settle(),
              child:Material(color:Colors.white,child:InkWell(
                onTap:(){if(offset!=0){setState(()=>offset=0);}else{widget.onOpen();}},
                child:Container(
                  padding:const EdgeInsets.symmetric(vertical:16,horizontal:2),
                  decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:Color(0xFFECECEC)))),
                  child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    SizedBox(width:44,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Text('${e.date.day}',style:const TextStyle(fontSize:26,height:1.05,fontWeight:FontWeight.w500)),
                      const SizedBox(height:3),
                      Text('${e.date.year}.${e.date.month}',style:const TextStyle(fontSize:10,color:Color(0xFF8A8A8A)))
                    ])),
                    const SizedBox(width:13),
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Text(e.title.isEmpty?'无标题':e.title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600)),
                      const SizedBox(height:6),
                      Text(preview,maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12.5,height:1.7,color:Color(0xFF777777)))
                    ]))
                  ])
                )
              ))
            )
          )
        ]
      )
    );
  }
}

class _Editor extends StatefulWidget {
  const _Editor({this.entry,required this.type});
  final _Entry? entry; final String type;
  @override State<_Editor> createState()=>_EditorState();
}
class _EditorState extends State<_Editor> {
  late final TextEditingController title,body,trTitle,trBody;
  late DateTime date;
  @override void initState(){super.initState();title=TextEditingController(text:widget.entry?.title??'');body=TextEditingController(text:widget.entry?.body??'');trTitle=TextEditingController(text:(widget.entry?.extra['trTitle']??'').toString());trBody=TextEditingController(text:(widget.entry?.extra['tr']??'').toString());date=widget.entry?.date??DateTime.now();}
  @override void dispose(){title.dispose();body.dispose();trTitle.dispose();trBody.dispose();super.dispose();}
  Future<void> _pickDate() async {final d=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime.now().add(const Duration(days:365)));if(d!=null)setState(()=>date=d);}
  void _mark(String color){
    final selection=body.selection;
    if(!selection.isValid||selection.isCollapsed){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('先选中一段文字哦')));return;}
    if(body.text.substring(selection.start,selection.end).contains('\n')){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('标记请在同一段文字内使用')));return;}
    final selected=body.text.substring(selection.start,selection.end).replaceAllMapped(RegExp(r'\[\[(?:红|蓝)[:：]([\s\S]*?)\]\]'),(m)=>m[1]??'');
    final value=color=='x'?selected:'[[$color:$selected]]';
    final next=body.text.replaceRange(selection.start,selection.end,value);
    body.value=TextEditingValue(text:next,selection:TextSelection.collapsed(offset:selection.start.toInt()+value.length));
  }
  void _save(){
    final text=body.text.trim();if(text.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('正文不能为空')));return;}
    final now=DateTime.now();
    final extra=<String,dynamic>{...?widget.entry?.extra,'tr':trBody.text.trim(),'trTitle':trTitle.text.trim()};
    Navigator.pop(context,_Entry(id:widget.entry?.id??now.microsecondsSinceEpoch.toString(),type:widget.type,owner:widget.entry?.owner??'me',title:title.text.trim(),body:text,date:date,time:now,image:widget.entry?.image??'',comment:widget.entry?.comment??'',extra:extra));
  }
  Widget _markButton(String label,String color)=>TextButton(onPressed:()=>_mark(color),child:Text(label,style:TextStyle(fontSize:12,color:color=='红'?const Color(0xFFD94A4A):color=='蓝'?const Color(0xFF3478D4):const Color(0xFF777777),decoration:color=='红'?TextDecoration.underline:null,backgroundColor:color=='蓝'?const Color(0x665BA8FF):null)));
  @override Widget build(BuildContext context){
    final note=widget.type=='note';
    return Scaffold(backgroundColor:const Color(0xFFFAFAFA),appBar:AppBar(backgroundColor:const Color(0xFFFAFAFA),surfaceTintColor:Colors.transparent,elevation:0,
      leading:TextButton(onPressed:()=>Navigator.pop(context),child:const Text('取消',style:TextStyle(color:Color(0xFF777777)))),
      title:Text(widget.entry==null?(note?'写留言':'写日记'):'编辑',style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:Color(0xFF111111))),centerTitle:true,
      actions:[TextButton(onPressed:_save,child:const Text('完成',style:TextStyle(color:Colors.black,fontWeight:FontWeight.w700))),const SizedBox(width:8)]),
      body:SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(22,12,22,32),children:[
        if(!note)...[
          Row(children:[const Icon(Icons.schedule,size:14,color:Color(0xFF999999)),const SizedBox(width:7),Text('${date.year}.${date.month}.${date.day}',style:const TextStyle(fontSize:11,color:Color(0xFF777777))),const Spacer(),TextButton(onPressed:_pickDate,child:const Text('更改日期',style:TextStyle(fontSize:11,color:Colors.black)))]),
          const SizedBox(height:13),TextField(controller:title,maxLength:40,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w600),decoration:const InputDecoration(counterText:'',hintText:'标题',border:InputBorder.none,hintStyle:TextStyle(color:Color(0xFFBBBBBB),fontWeight:FontWeight.w400))),
          const Divider(height:1,color:Color(0xFFECECEC)),
          Padding(padding:const EdgeInsets.only(top:10,bottom:3),child:Row(children:[_markButton('红线','红'),_markButton('荧光笔','蓝'),_markButton('清除标记','x')])),
        ],
        const SizedBox(height:8),TextField(controller:body,autofocus:true,minLines:note?4:12,maxLines:null,keyboardType:TextInputType.multiline,style:const TextStyle(fontSize:15,height:1.95,color:Color(0xFF222222)),decoration:InputDecoration(hintText:note?'留下一句想说的话…':'写点什么…',border:InputBorder.none,hintStyle:const TextStyle(color:Color(0xFFBBBBBB),fontSize:14))),
        if(!note)...[
          const SizedBox(height:24),const Text('译文（可选）',style:TextStyle(fontSize:12,color:Color(0xFF888888))),
          const SizedBox(height:8),TextField(controller:trTitle,decoration:const InputDecoration(hintText:'标题译文',border:InputBorder.none)),
          TextField(controller:trBody,minLines:3,maxLines:null,decoration:const InputDecoration(hintText:'外语日记的中文译文',border:InputBorder.none)),
        ]
      ]))
    );
  }
}

class _Reader extends StatefulWidget {
  const _Reader({required this.entry,required this.onEdit,required this.onDelete,required this.onComment,required this.decorText,required this.ownerName});
  final _Entry entry;final VoidCallback onEdit,onDelete;final ValueChanged<String> onComment;final String decorText,ownerName;
  @override State<_Reader> createState()=>_ReaderState();
}
class _ReaderState extends State<_Reader>{
  late final TextEditingController comment;
  bool translated=false;
  @override void initState(){super.initState();comment=TextEditingController(text:widget.entry.comment);}
  @override void dispose(){comment.dispose();super.dispose();}
  List<InlineSpan> _marked(String source){
    final spans=<InlineSpan>[];final reg=RegExp(r'\[\[(红|蓝)[:：]([\s\S]*?)\]\]');var at=0;
    for(final m in reg.allMatches(source)){if(m.start>at)spans.add(TextSpan(text:source.substring(at,m.start)));final red=m[1]=='红';spans.add(TextSpan(text:m[2],style:red?const TextStyle(decoration:TextDecoration.underline,decorationColor:Color(0xFFE45B62),decorationThickness:2.2):const TextStyle(backgroundColor:Color(0x665BA8FF))));at=m.end;}
    if(at<source.length)spans.add(TextSpan(text:source.substring(at)));return spans;
  }
  @override Widget build(BuildContext context){
    final e=widget.entry;final tr=(e.extra['tr']??'').toString();final trTitle=(e.extra['trTitle']??'').toString();
    final paragraphs=(translated&&tr.isNotEmpty?tr:e.body).split('\n');
    return Scaffold(backgroundColor:const Color(0xFFF7F7F7),appBar:AppBar(backgroundColor:const Color(0xFFF7F7F7),surfaceTintColor:Colors.transparent,elevation:0,
      leading:IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.arrow_back_ios_new,size:18)),title:const Text('日记',style:TextStyle(fontSize:14,fontWeight:FontWeight.w600)),centerTitle:true,
      actions:[IconButton(onPressed:widget.onEdit,icon:const Icon(Icons.edit_outlined,size:19)),PopupMenuButton<String>(onSelected:(v){if(v=='delete')widget.onDelete();},itemBuilder:(_)=>const[PopupMenuItem(value:'delete',child:Text('删除'))])]),
      body:SafeArea(child:Column(children:[
        Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(14,6,14,24),children:[
          Container(margin:const EdgeInsets.only(left:9),padding:const EdgeInsets.fromLTRB(28,24,20,30),constraints:const BoxConstraints(minHeight:520),
            decoration:BoxDecoration(color:Colors.white,borderRadius:const BorderRadius.horizontal(left:Radius.circular(4),right:Radius.circular(14)),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.05),blurRadius:22,offset:const Offset(0,8))]),
            child:Stack(children:[
              Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_DiaryDotPainter()))),
              Positioned(left:-27,top:4,bottom:4,child:Column(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:List.generate(7,(_)=>Container(width:14,height:14,decoration:BoxDecoration(color:const Color(0xFFF7F7F7),shape:BoxShape.circle,border:Border.all(color:const Color(0xFFE6E6E6))))))),
              Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[CircleAvatar(radius:18,backgroundColor:const Color(0xFFF0F0F0),child:Text(widget.ownerName=='我'?'我':'T',style:const TextStyle(color:Color(0xFF111111),fontSize:12))),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(widget.ownerName,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600)),Text(widget.ownerName=='我'?'@me':'@companion',style:const TextStyle(fontSize:10,color:Color(0xFF999999)))])),Text('${e.date.year}/${e.date.month}/${e.date.day}  ${e.time.hour.toString().padLeft(2,'0')}:${e.time.minute.toString().padLeft(2,'0')}',style:const TextStyle(fontSize:10,color:Color(0xFF999999)))]),
                const SizedBox(height:17),
                if(widget.decorText.isNotEmpty)Padding(padding:const EdgeInsets.only(bottom:18),child:Text(widget.decorText,style:const TextStyle(fontSize:13,height:1.6,color:Color(0xFF777777)))),
                const Row(children:[Icon(Icons.chat_bubble_outline_rounded,size:15,color:Color(0xFF999999)),SizedBox(width:7),Text('写于 Mio Diary',style:TextStyle(fontSize:11,color:Color(0xFF999999),fontStyle:FontStyle.italic))]),
                const SizedBox(height:24),
                if(e.title.isNotEmpty)GestureDetector(onTap:trTitle.isEmpty?null:()=>setState(()=>translated=!translated),child:Text(translated&&trTitle.isNotEmpty?trTitle:e.title,style:const TextStyle(fontSize:23,height:1.4,fontWeight:FontWeight.w600))),
                if(e.title.isNotEmpty)const SizedBox(height:18),
                GestureDetector(onTap:tr.isEmpty?null:()=>setState(()=>translated=!translated),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:paragraphs.map((p)=>Padding(padding:const EdgeInsets.only(bottom:13),child:RichText(text:TextSpan(style:const TextStyle(fontSize:15,height:1.95,color:Color(0xFF222222)),children:_marked(p))))).toList())),
                const SizedBox(height:28),const Divider(color:Color(0xFFECECEC)),const SizedBox(height:14),const Text('留言',style:TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:Color(0xFF777777))),
                if(e.comment.isNotEmpty)Padding(padding:const EdgeInsets.only(top:12),child:Text(e.comment,style:const TextStyle(fontSize:13,height:1.7))),
              ])
            ])
          ),
        ])),
        SafeArea(top:false,child:Container(padding:const EdgeInsets.fromLTRB(12,8,12,8),decoration:const BoxDecoration(color:Colors.white,border:Border(top:BorderSide(color:Color(0xFFECECEC)))),
          child:Row(children:[Expanded(child:TextField(controller:comment,minLines:1,maxLines:4,decoration:InputDecoration(hintText:'回复帖子 @我',isDense:true,filled:true,fillColor:const Color(0xFFF7F7F7),border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide.none),contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:10)))),const SizedBox(width:8),IconButton(onPressed:(){widget.onComment(comment.text.trim());FocusScope.of(context).unfocus();},icon:const Icon(Icons.send_rounded,size:19))])
        ))
      ]))
    );
  }
}
class _DiaryDotPainter extends CustomPainter {
  @override void paint(Canvas canvas,Size size){final p=Paint()..color=const Color(0xFFE8E8E8);for(double y=8;y<size.height;y+=14){for(double x=8;x<size.width;x+=14){canvas.drawCircle(Offset(x,y),.65,p);}}}
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

class _Entry {
  _Entry({required this.id,required this.type,required this.owner,required this.title,required this.body,required this.date,required this.time,this.image='',this.comment='',this.extra=const {}});
  final String id,type,owner,title,body,image;
  final DateTime date,time;
  final Map<String,dynamic> extra;
  String comment;
  String get displayBody {
    final lines=body.split('\n').toList();
    var first=0;
    while(first<lines.length&&lines[first].trim().isEmpty){first++;}
    String norm(String value)=>value
      .replaceAll(RegExp(r'\[\[(?:红|蓝)[:：]([\s\S]*?)\]\]'),r'$1')
      .replaceAll(RegExp(r'[\s\p{P}\p{S}]',unicode:true),'')
      .toLowerCase();
    if(title.isNotEmpty&&first<lines.length&&norm(lines[first])==norm(title))lines.removeAt(first);
    while(lines.isNotEmpty&&lines.first.trim().isEmpty){lines.removeAt(0);}
    return lines.join('\n');
  }
  Map<String,dynamic> toMap()=>{...extra,'id':id,'type':type,'owner':owner,'title':title,'body':body,'content':body,'date':date.toIso8601String(),'time':time.toIso8601String(),'updatedAt':time.toIso8601String(),'imagePath':image,'image':image,'comment':comment};
  factory _Entry.fromMap(Map m){
    DateTime? parseDate(dynamic value) {
      if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }
    final rawTime=m['time']??m['updatedAt']??m['createdAt'];
    final d=parseDate(m['date'])??parseDate(rawTime)??DateTime.now();
    final t=parseDate(rawTime)??d;
    final known={'id','type','owner','title','body','content','date','time','updatedAt','createdAt','imagePath','image','comment'};
    final extras=<String,dynamic>{};
    for(final entry in m.entries){if(!known.contains(entry.key.toString()))extras[entry.key.toString()]=entry.value;}
    final rawOwner=(m['owner']??m['pid']??'me').toString();
    return _Entry(
      id:(m['id']??DateTime.now().microsecondsSinceEpoch).toString(),
      type:(m['type']??'long').toString(),
      owner:rawOwner=='me'?'me':(rawOwner=='ta'?'ta':'ta'),
      title:(m['title']??'').toString(),
      body:(m['body']??m['content']??'').toString(),
      date:d,time:t,
      image:(m['imagePath']??m['image']??'').toString(),
      comment:(m['comment']??'').toString(),
      extra:extras,
    );
  }
}
