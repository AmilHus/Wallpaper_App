import "dart:async";
import "dart:convert";
import "dart:io";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import "package:path_provider/path_provider.dart";
import 'package:dio/dio.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State <HomeScreen> createState(){ 
    return _HomeScreenState();
     }

  
}

class UnsplashService {
  http.Client client = http.Client();

  final String _accessKey = '43EkVmFwu78fBz-zOMQKuIg_GvfVcHkvy9GT-ALvbAw';

  Future<List> fetchDataFromApi( int page) async {
    try{
      List imagesUrl = [];
      await Future.delayed(const Duration(seconds: 3),() async{
      var jsonData = await http.get(
          Uri.parse(
              // ignore: unnecessary_brace_in_string_interps
              'https://api.unsplash.com/photos/?page=${page}&per_page=30&popular&client_id=$_accessKey'))
              .timeout(const Duration(seconds: 10));
      var fetchData = jsonDecode(jsonData.body);
      
      var  data = fetchData;
        for (var element in data) {
          imagesUrl.add(element['urls']['regular'].toString());
        }});
      return imagesUrl;
    }
    catch (e){
      throw Exception(e);
    }
  }

   Future<List> searchDataFromApi(String query, int searchPage) async {
    try{
      List imagesUrl = [];
      await Future.delayed(const Duration(seconds: 3),() async{
       
       var jsonData = await http.get(
          // ignore: unnecessary_brace_in_string_interps
          Uri.parse('https://api.unsplash.com/search/photos?page=${searchPage}&per_page=30&query=$query&client_id=$_accessKey'))
          .timeout(const Duration(seconds: 10));
      var fetchData = jsonDecode(jsonData.body);
      var data = fetchData['results'];
          for (var element in data) {
            imagesUrl.add(element['urls']['regular'].toString());
          }

      });
      return imagesUrl;
      
    }
    catch (e){
      throw Exception(e);
    }
  }
}




class DownloadService   {
  final Dio dio;
  final StreamController<int> progressController = StreamController<int>.broadcast();
  DownloadService({required this.dio});
  http.Client client = http.Client();
  
  Future<void> downloadImage(String url,file) async {
    
    try {      
      
        await dio.download(url, file,onReceiveProgress: (count, total) {
              int progress = ((count / total) * 100).toInt();
              progressController.add(progress);
          });
        }
  catch(e){
    throw Exception(e);
  }
  }
}


class _HomeScreenState extends State<HomeScreen>{
  List data = [];
  List imagesUrl = [];
  
  int page = 1;
  int searchPage = 1;

  bool isLoading = false;
  bool isDownloading = false;
  late UnsplashService _unsplashService;
  late DownloadService _imageService;

  ScrollController _controller = ScrollController();

  final TextEditingController _searchController = TextEditingController();
  final progressController = StreamController();
  @override
  void initState() {
      super.initState();
      _unsplashService =  UnsplashService();
      _imageService = DownloadService(dio: Dio());
      _controller = ScrollController()..addListener(_scrollListener);
      _fetchPhotos();
  }

  @override
  void dispose() {
    _controller.removeListener(_scrollListener);
    _imageService.progressController.close();
    super.dispose();
  }

  Future<void> _searchPhotos() async {
    
    try {
      setState(() {
      isLoading = true;
    });
      if (_searchController.text.isEmpty){
        imagesUrl.clear;
        _fetchPhotos();
      }
    else{

      var photos = await _unsplashService.searchDataFromApi(_searchController.text, searchPage);
      setState(() {
        imagesUrl.addAll(photos);
      });
      }
    }
      catch(e){
         Fluttertoast.showToast(
                  msg: e.toString(),
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0
              );
      }
      setState(() {
        isLoading = false;
      });
  }

  Future<void> _fetchPhotos() async {
    setState(() {
      isLoading = true;
    });
    try{
      var photos = await _unsplashService.fetchDataFromApi(page);
      setState(() {
        imagesUrl.addAll(photos);
      });
    }
    catch(e){
      Fluttertoast.showToast(
        msg: e.toString(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
        );
    }
    setState(() {
      isLoading = false;
    });
  }

  Future <void>  downloadImage(int index)  async{
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path;
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

        try {
          _imageService.progressController.stream.listen((progress) {
            setState(() {
            isDownloading = true;
          });
           });
          await _imageService.downloadImage(imagesUrl[index], '$path/$fileName');
         setState(() {
            isDownloading = false;
          });
        } catch (e) {
          Fluttertoast.showToast(
                  msg: e.toString(),
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: null,
       body:  Padding(
          padding: const EdgeInsets.symmetric(horizontal:16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                margin: const EdgeInsets.only(top:40.0, bottom:20, left:8, right:8),
                  decoration: BoxDecoration(
                    color: const Color(0xCC222222),
                    border: Border.all(color: const Color(0xFF878E8F)),
                    borderRadius:BorderRadius.circular(25),
                  ),
            child:  TextField(
              controller: _searchController ,
              onChanged: (function) {
                Future.delayed( const Duration( seconds: 3), () {
                  imagesUrl.clear();
                  page = 1;
                  searchPage = 1;
                  _searchPhotos();
                });
              },
              style: const TextStyle(
                color: Color(0xFFF4FEFF),
                fontFamily: 'ZenMaruGothic',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                ),
              decoration: const InputDecoration(
                hintStyle: TextStyle(color: Color(0xFFF4FEFF)),
                prefixIconColor: Color.fromARGB(255, 130, 130, 123),
                prefixIcon: Icon(Icons.search),
                hintText: "Search",
                errorBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                border: InputBorder.none,
              ),
              
            )
          ),
              Expanded(
                child: Scrollbar(controller: _controller ,
                child:GridView.custom(controller: _controller, physics: const BouncingScrollPhysics(),
                 gridDelegate: SliverQuiltedGridDelegate(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  pattern: const [
                    QuiltedGridTile(1, 1),
                    QuiltedGridTile(1, 1),
                    QuiltedGridTile(1, 2),
                  ]
                ),
                 childrenDelegate: SliverChildBuilderDelegate(childCount: imagesUrl.length ,(context, index) { 
                   return  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GestureDetector( onDoubleTap: () => downloadImage(index) ,
                      child: CachedNetworkImage(imageUrl: imagesUrl[index],
                        fit: BoxFit.fill,
                        imageBuilder:(context, imageProvider) =>  Container(
                          decoration: BoxDecoration(borderRadius:BorderRadius.circular(10),
                          color: Colors.white,
                          image:  DecorationImage(image: imageProvider,fit: BoxFit.cover))),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                        placeholder: ((context, url, ) =>  Transform.scale(
                          scale: 2 ,
                          child:const Center(child:CircularProgressIndicator(color: Color.fromARGB(255,237,233,57)))))
                    )));
                  })),
                  ))
                  ,Visibility(
                        visible: isLoading,
                        child: const LinearProgressIndicator(color: Colors.yellow,backgroundColor: Colors.black,),
                      ),
                  Visibility(
                        visible: isDownloading,
                        child: StreamBuilder<int>(
                          stream: _imageService.progressController.stream,
                          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                            if (snapshot.hasData) {
                              return LinearProgressIndicator(value: snapshot.data! / 100,color: Colors.green,backgroundColor: Colors.black,);
                            } else {
                              return const LinearProgressIndicator();
                            }
                          },
                        ),
                      )
            ],
        )),
      );
    }

  void _scrollListener() {
    if (_controller.position.maxScrollExtent == _controller.position.pixels &&  _searchController.text.toString().isEmpty) {
        page++;
         _fetchPhotos();
      }
    if  (_controller.position.maxScrollExtent == _controller.position.pixels &&  _searchController.text.toString().isNotEmpty ) {
        searchPage++;
        _searchPhotos();
    }}
}