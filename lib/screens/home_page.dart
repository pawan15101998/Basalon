import 'dart:async';
import 'package:basalon/network/get_events_network.dart';
import 'package:basalon/network/package_network.dart';
import 'package:basalon/services/constant.dart';
import 'package:basalon/services/my_color.dart';
import 'package:basalon/widgets/custom_buttons.dart';
import 'package:basalon/widgets/dropdown_anywhere.dart';
import 'package:basalon/widgets/dropdown_everywhere.dart';
import 'package:basalon/widgets/dropdown_time.dart';
import 'package:basalon/widgets/event_card.dart';
import 'package:basalon/widgets/google_map.dart';
import 'package:basalon/widgets/scroll_to_hide.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import '../blocs/application_bloc.dart';
import '../constant/login_user.dart';
import '../network/get_update_profile_network.dart';
import '../utils/utils.dart';
import '../widgets/date_helper.dart';
import '../widgets/dropDownButton1.dart';
import '../widgets/side_drawer.dart';
import 'activity/receiving_activity_screen.dart';
class HomePage extends StatefulWidget {
  var categoryFilter;
  var userIdLocal;
  HomePage({this.categoryFilter});

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final FetchEventData _fetchEventData = FetchEventData();
  int numOfEvents = 10;
  final ScrollController _scrollViewController =
      ScrollController(keepScrollOffset: true);
  final StreamController<bool> _appBarController = StreamController.broadcast();
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  bool showToolBar = false;
  bool showToolBarRow = false;

  bool loading = false;
  int? radiusVal = 0;
  int page = 1;
  late double width = MediaQuery.of(context).size.width;
  final GlobalKey _contentKey = GlobalKey();
  final GlobalKey _refresherKey = GlobalKey();
  dynamic category;
  bool toggleCheck = false;

  // dynamic filterCategory;
  dynamic filterByTime;
  dynamic filterByAnywhere;
  late final application = Provider.of<ApplicationBloc>(context, listen: false);
  StreamSubscription? locationSubscription;
  final UpdateAndGetUserProfile _updateAndGetUserProfile =
      UpdateAndGetUserProfile();

  PackageNetwork packageNetwork = PackageNetwork();


  @override
  void initState() {
    Future.delayed(Duration(milliseconds: 100), () {
      setLocation();
    });
    print('home page initstate');
    print(application.getUserDataProfileProvider?.data?.authorImage);

    LoginUser.shared?.userId != null
        ? packageNetwork.getPackage(
            LoginUser.shared?.userId! ?? application.idFromLocalProvider,
            context)
        : "";
    super.initState();
    _scrollViewController.addListener;
    // _fetchEventData.getEventData(page,application.filterCategoryProvider, filterByTime);
    _fetchEventData.getEventCategories();
    locationSubscription = application.selectedLocation.stream.listen((place) {
      print(place);
      if (place != null) {
        _goToPlace(place);
      }
    });
  print(application.idFromLocalProvider);
    print("TTTTTTTTTTTT");
    print(LoginUser.shared?.userId);

    
    _updateAndGetUserProfile.getProfileData(
          LoginUser.shared?.userId! ?? application.idFromLocalProvider,
          context: context) ;

    // _updateAndGetUserProfile.getProfileData('1863', context: context);
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    print('didChangeDependencies');
    super.didChangeDependencies();
    LoginUser.shared?.userId != null
        ? _updateAndGetUserProfile.getProfileData(
            LoginUser.shared?.userId! ?? application.idFromLocalProvider,
            context: context)
        : "";
    // _updateAndGetUserProfile.getProfileData(
    //         "1770",
    //         context: context);
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    // TODO: implement didUpdateWidget
    print('didUpdateWidget');

    super.didUpdateWidget(oldWidget);
    setState(() {});
  }

  @override
  void dispose() {
    _scrollViewController.removeListener;
    _appBarController.close();
    _scrollViewController.dispose();
    _refreshController.dispose();
    categorySearchController.dispose();
    locationController.dispose();
    locationController.clear();
    startDateController.dispose();
    endDateController.dispose();
    categorySearchController.dispose();
    locationController.dispose();
    super.dispose();
  }



  void _onLoading(){
    print("on lading chrla"); // monitor network fetch
    page += 1;  if(application.filterAnywhereProvider != null) {
      _fetchEventData.getEventData(
        page,
        context,
        application.filterTimeProvider ?? filterByTime,
        context,
        klatitude ?? geoLoc?.latitude,
        klongitude ?? geoLoc?.longitude,
        categorySearchController.text,
        startDateController.text,
        endDateController.text,
        context);
    }
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  void _onRefresh() async {
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    page = 1;
    setState(() {});
    _refreshController.refreshCompleted();
  }
  Stream streamController() => Stream.fromFuture(
    _fetchEventData.getEventData(
      page,
      application.filterCategoryProvider,
      application.filterTimeProvider,
      application.filterAnywhereProvider,
      klatitude ?? geoLoc?.latitude,
      klongitude ?? geoLoc?.longitude,
      categorySearchController.text,
      startDateController.text,
      endDateController.text,
      context));
  bool showMap = false;
  bool showOnline = false;

  List dropItems = kCategoryList;
  List<bool> dropItemsHandler = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ];

  // List dropItemsss = [];

  // List dropItems = [];
  List selectedDropItems = [];

  String? dropText;
  bool? dropTextColorHandler;
  Position? geoLoc;

  setLocation() async {
    geoLoc = await Geolocator.getCurrentPosition();

    print(
        '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++homepage');
    print(geoLoc);

    setState(() {
      if(geoLoc != null){
        application.filterAnywhereProvider = 'קרוב אליי';
      }else{
        application.filterAnywhereProvider = 'בכל מקום';
      }
    });
    
    return geoLoc;
  }

  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController categorySearchController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  final translator = GoogleTranslator();
  Translation? translatedData;
  dynamic increaseHeight = 20.0;

  DateTime timeBackPressed = DateTime.now();
  String? val;

  @override
  Widget build(BuildContext context) {
    print('----------------------');
    print('network image');
    print(application.getUserDataProfileProvider?.data?.authorImage);
    print(application.getUserDataProfileProvider?.data?.authorImage);
    return SafeArea(
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: MyColors.homeBackGroundColor,
        endDrawer: NavDrawer(
          packageID: packageNetwork.packageModel?.data?.userActivePackage?.iD,
          profileData: _updateAndGetUserProfile.getUserData,
        ),
        body:
         StreamBuilder(
          initialData:
          //  application.filterAnywhereProvider != null ?
              _fetchEventData.getEventData(
              page,
              application.filterCategoryProvider,
              application.filterTimeProvider,
              application.filterAnywhereProvider,
              klatitude ?? geoLoc?.latitude,
              klongitude ?? geoLoc?.longitude,
              categorySearchController.text,
              startDateController.text,
              endDateController.text,
              // ((application.filterAnywhereProvider == 'online') &&
              //         (application.showOnline == true))
              //     ? "online"selectedDropItems.length
              //     : "classic",
              
              
              
              context),
          stream: streamController(),
          builder: (context, AsyncSnapshot snapshot) {
            return SmartRefresher(
              key: _refresherKey,
              controller: _refreshController,
              enablePullUp: true,
              enablePullDown: false,
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              footer: CustomFooter(
                builder: (BuildContext context, LoadStatus? mode) {
                  Widget body;
                  if (mode == LoadStatus.idle) {
                    body = Container(
                        margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height),
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height),
                        child: Text("No more Data"));
                  } else if (mode == LoadStatus.loading) {
                    body = Container(
                        margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height),
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height),
                        child: CupertinoActivityIndicator());
                  } else if (mode == LoadStatus.failed) {
                    body = Text("Load Failed!Click retry!");
                  } else if (mode == LoadStatus.canLoading) {
                    body = Text("release to load more");
                  } else {
                    body = Text("No more Data");
                  }
                  return SizedBox(
                    height: 55.0,
                    child: Center(child: body),
                  );
                },
              ),
              child: CustomScrollView(
                key: _contentKey,
                controller: _scrollViewController,
                physics: snapshot.connectionState == ConnectionState.waiting
                    ? NeverScrollableScrollPhysics()
                    : null,
                slivers: [
                  SliverAppBar(
                    collapsedHeight: 50,
                    toolbarHeight: 0,
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.black,
                    pinned: false,
                    //expandedHeight: MediaQuery.of(context).size.height * 0.6,
                    expandedHeight: 650,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Container(
                        padding: EdgeInsets.only(bottom: 20),
                        // height: 450,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                alignment: Alignment(-0.1, 0.0),
                                scale: 1.0,
                                fit: BoxFit.cover,
                                image: Image.asset(
                                  'assets/homePageBannerNew.jpg',
                                ).image)),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            AppBar(
                              leading: (isUserLogin(application.isUserLogin) &&
                                      application.getUserDataProfileProvider
                                              ?.data?.authorImage !=
                                          null)
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CircleAvatar(
                                        backgroundImage:
                                            // AssetImage(
                                            //     'assets/images/dummy_user.png'),
                                            NetworkImage(
                                          application.getUserDataProfileProvider
                                                      ?.data?.authorImage !=
                                                  ''
                                              ? application
                                                  .getUserDataProfileProvider
                                                  ?.data
                                                  ?.authorImage
                                              : application.imageFromFacebook ??
                                                  'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460__340.png',
                                        ),
                                        backgroundColor: Colors.grey.shade600,
                                      ),
                                    )
                                  : SizedBox(),
                              elevation: 0,
                              // backgroundColor: Colors.transparent,
                              backgroundColor: Colors.black.withOpacity(0),

                              title: Container(
                                decoration: const BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black,
                                        blurRadius: 100.0,
                                        // soften the shadow
                                        spreadRadius: 10.0,
                                        //extend the shadow
                                        offset: Offset(
                                          -20.0,
                                          // Move to right 10  horizontally
                                          -30.0, // Move to bottom 10 Vertically
                                        ),
                                        blurStyle: BlurStyle.normal),
                                  ],
                                ),
                                child: Image.asset(
                                  kLogoImage,
                                  fit: BoxFit.fill,
                                ),
                              ),
                              actions: [
                                Builder(
                                  builder: (context) => Container(
                                    margin: const EdgeInsets.only(right: 15),
                                    padding: EdgeInsets.zero,
                                    child: GestureDetector(
                                        onTap: () => Scaffold.of(context)
                                            .openEndDrawer(),
                                        child: const Icon(
                                          Icons.menu,
                                          size: 40,
                                        )),
                                  ),
                                )
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              // crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Column(
                                  children: [
                                    const Text(
                                      'אז... מה עושים היום?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        shadows: <Shadow>[
                                          Shadow(
                                            offset: Offset(2.0, 2.0),
                                            blurRadius: 3.0,
                                          )
                                        ],
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 38.0,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                   const  SizedBox(height: 10),
                                    const Text(
                                      'גלו הרצאות, סדנאות, הופעות',
                                      textAlign: TextAlign.center,
                                      style: ktextStyleWhiteLarge,
                                      // maxLines: 1,
                                    ),
                                    const Text(
                                      'וארוחות בסלון הקרוב אליכם',
                                      textAlign: TextAlign.center,
                                      style: ktextStyleWhiteLarge,
                                    ),
                                    SizedBox(height: 30),
                                    application.filterAnywhereProvider ==
                                            'עיר מסויימת'
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 18),
                                            child: Directionality(
                                              textDirection: TextDirection.rtl,
                                              child: ReceivingPaymentFields(
                                                isFocus: true,
                                                textColorPrimary: Colors.white,
                                                maxLine: 1,
                                                showRequired: false,
                                                showLabel: false,
                                                controller: locationController,
                                                onChange: (v) {
                                                  application.searchPlaces(v);
                                                  print('eeeeeeeeeeeeeeee$v');
                                                  setState(() {});
                                                },
                                                onFieldSubmit: (v) {
                                                  application.searchPlaces(v);
                                                  print('eeeeeeeeeeeeeeee$v');
                                                },
                                                textColor: Colors.white,
                                                colors: MyColors.dropdownColor,
                                                obscureText: false,
                                                hintText: 'הקלד/י עיר',
                                                suffixIcon: IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      application
                                                              .filterAnywhereProvider =
                                                          null;
                                                      locationController
                                                          .clear();
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          )
                                        : DropButtonEverywhere(
                                            coordinates: geoLoc,
                                            text1: 'איפה?',
                                            text2: 'בכל מקום',
                                            onChanged: (value) {
                                              print(
                                                  'value from value from value from value from ');
                                              print(value);
                                              setState(() {
                                                application
                                                        .filterAnywhereProvider =
                                                    value.toString().replaceAll(
                                                        'אונליין / זום',
                                                        'online');
                                                application.showOnline =
                                                    !showOnline;
                                                page = 1;
                                              });
                                              if (value == 'בכל מקום') {
                                                print(
                                                    'chli kya condition ??????????/');
                                                setState(() {
                                                  application
                                                      .filterCategoryProvider = '';
                                                  // application.filterTimeProvider =
                                                  //     '';
                                                  application
                                                          .filterAnywhereProvider =
                                                      'בכל מקום';
                                                  categorySearchController
                                                      .text = '';
                                                  endDateController.text = '';
                                                  startDateController.text = '';
                                                  klatitude = null;
                                                  klongitude = null;
                                                  page = 1;
                                                });
                                              }
                                              if (value == 'קרוב אליי') {
                                                klatitude = null;
                                                klongitude = null;
                                              }
                                              if (value == "עיר מסויימת") {
                                                // application.filterAnywhereProvider = "start-date";
                                                //
                                              }
                                            },
                                          ),

                                    SizedBox(height: increaseHeight),
                                    DropButton1(
                                      text1: 'מתי?',
                                      text2: 'ב-7 ימים הקרובים',
                                      onChanged: (v) {
                                        setState(() {
                                          application.filterTimeProvider = v;
                                          page = 1;
                                        });
                                        print(
                                            'filterByTime filterByTime filterByTime filterByTime');
                                        print(v);
                                      },
                                    ),
                                    SizedBox(height: 10),
                                    if (application.filterTimeProvider ==
                                        'specific_date')
                                      Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 18),
                                          child: Row(
                                            children: [
                                              ReceivingPaymentFields(
                                                hintText: 'החל מתאריך...',
                                                textColor: Colors.white,
                                                width: 130,
                                                textColorPrimary: Colors.white,
                                                colors: MyColors.dropdownColor,
                                                obscureText: false,
                                                controller: startDateController,
                                                onTap: () async {
                                                  var date = await selectDate(
                                                      isDob: true,
                                                      context: context);
                                                  if (date != "null") {
                                                    setState(() {
                                                      startDateController.text =
                                                          convertSingleDate(
                                                              date);
                                                    });
                                                  }
                                                },
                                              ),
                                              SizedBox(width: 10),
                                              ReceivingPaymentFields(
                                                textColor: Colors.white,
                                                hintText: 'עד תאריך...',
                                                width: 130,
                                                textColorPrimary: Colors.white,
                                                colors: MyColors.dropdownColor,
                                                obscureText: false,
                                                controller: endDateController,
                                                onTap: () async {
                                                  var date = await selectDate(
                                                      isDob: true,
                                                      context: context);
                                                  if (date != "null") {
                                                    setState(() {
                                                      endDateController.text =
                                                          convertSingleDate(
                                                              date);
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    SizedBox(height: 10),
                                    // DropdownCategories(
                                    //   categories: _fetchEventData
                                    //       .filterCategoryModel?.data,
                                    //   text1: 'מה?',
                                    //   text2: 'כל החוויות',
                                    //   onChanged: (value) {
                                    //     setState(() {
                                    //       application.filterCategoryProvider =
                                    //           value;
                                    //     });
                                    //   },
                                    // ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          showToolBar = !showToolBar;
                                        });
                                      },
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10),
                                        color: MyColors.dropdownColor,
                                        height: 50,
                                        width: double.infinity,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.white,
                                            ),
                                            // Text(
                                            //   'מה? \n ${dropText != null ? dropText : '${selectedDropItems.length != 0 ? selectedDropItems.length : ''} כל החוויות'} ',
                                            //   textDirection: TextDirection.rtl,
                                            //   style: ktextStyleSmallWhite,
                                            // ),
                                            RichText(
                                              textDirection: TextDirection.rtl,
                                              text: TextSpan(
                                                text: 'מה?\n',
                                                style: ktextStyleSmallWhite,
                                                children: [
                                                  TextSpan(
                                                      text:
                                                          '${selectedDropItems.isNotEmpty ? selectedDropItems.length : ''} ',
                                                      style: ktextStyleWhite),
                                                  TextSpan(
                                                      text: selectedDropItems
                                                              .isEmpty
                                                          ? 'כל החוויות'
                                                          : 'נבחרו',
                                                      style: ktextStyleWhite),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                            if (application.searchResult != null &&
                                application.searchResult?.length != 0 &&
                                application.filterAnywhereProvider ==
                                    'עיר מסויימת' &&
                                locationController.text.isNotEmpty)
                              Positioned(
                                top: 250,
                                right: 0,
                                left: 0,
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 20),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    // boxShadow: [
                                    //   BoxShadow(
                                    //     color: Colors.grey,
                                    //     blurRadius: 15.0,
                                    //     // soften the shadow
                                    //     spreadRadius: 0.1,
                                    //     //extend the shadow
                                    //     offset: Offset(
                                    //       15.0,
                                    //       // Move to right 10  horizontally
                                    //       15.0, // Move to bottom 10 Vertically
                                    //     ),
                                    //   )
                                    // ],
                                  ),
                                  height: 190,
                                  // width: double.infinity,
                                  child: ListView.separated(
                                      padding: const EdgeInsets.all(0),
                                      separatorBuilder: (context, index) =>
                                          const Divider(
                                            color: Colors.grey,
                                          ),
                                      itemCount:
                                          application.searchResult!.length,
                                      itemBuilder: (context, index) {
                                        // translator
                                        //     .translate(
                                        //     application.searchResult?[index]
                                        //         .description,
                                        //     to: 'iw')
                                        //     .then((value) {
                                        //   translatedData = value;
                                        // });

                                        return ListTile(
                                          visualDensity: VisualDensity.compact,
                                          dense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 0, horizontal: 10),
                                          trailing: Icon(Icons.location_on),
                                          onTap: () async {
                                            print('list tile dabao');

                                            locationController.text =
                                                // translatedData!.text;
                                                application.searchResult?[index]
                                                    .description;
                                            application.setSelectedLocation(
                                                application.searchResult![index]
                                                    .placeId, context);
                                            setState(() {});
                                          },
                                          title: application
                                                      .searchResult?[index]
                                                      .description ==
                                                  null
                                              ? CupertinoActivityIndicator()
                                              : Text(
                                                  "${application.searchResult?[index].description}",
                                                  // "${translatedData?.text}",
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 11),
                                                  textDirection:
                                                      TextDirection.rtl,
                                                  textAlign: TextAlign.start,
                                                ),
                                        );
                                      }),
                                ),
                              ),
                            if (showToolBar)
                              Positioned(
                                  top: 80,
                                  right: 0,
                                  left: 0,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    padding: EdgeInsets.only(top: 10),
                                    width: MediaQuery.of(context).size.width,
                                    color: Colors.white,
                                    child: Column(
                                      children: [
                                        Container(
                                          margin: EdgeInsets.all(10),
                                          padding: EdgeInsets.zero,
                                          child: const Text(
                                            'ניתן לבחור יותר מקטגוריה אחת',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Container(
                                          height: 330,
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            itemBuilder: (context, index) {
                                              return Container(
                                                color:
                                                    dropItemsHandler[index] ==
                                                            true
                                                        ? MyColors.topOrange
                                                        : Colors.white,
                                                child: CheckboxListTile(
                                                  selectedTileColor: Colors.red,
                                                  selected:
                                                      dropItemsHandler[index],
                                                  side: BorderSide(
                                                    width: 0.5,
                                                    color: Colors.grey,
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.lerp(
                                                          VisualDensity.compact,
                                                          VisualDensity.compact,
                                                          0.0),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  dense: true,
                                                  activeColor:
                                                      MyColors.topOrange,
                                                  value: selectedDropItems
                                                      .toString()
                                                      .toLowerCase()
                                                      .contains(
                                                          '${dropItems[index].toString().toLowerCase()}'),
                                                  onChanged: (value) {
                                                    dropTextColorHandler =
                                                        value;
                                                    dropItemsHandler[index] =
                                                        value!;
                                                    print(value);
                                                    setState(() {
                                                      if (value == true) {
                                                        selectedDropItems.add(
                                                            dropItems[index]);
                                                        String realValue = selectedDropItems
                                                            .toString()
                                                            .replaceAll('[', '')
                                                            .replaceAll(']', '')
                                                            .replaceAll(
                                                                ', ', ',')
                                                            .replaceAll(
                                                                'הרצאה', 'lecture')
                                                            .replaceAll(
                                                                'אירוח קולינרי',
                                                                'meals')
                                                            .replaceAll(
                                                                'הופעה/מופע', 'show')
                                                            .replaceAll(
                                                                'מפגש חברתי',
                                                                'group')
                                                            .replaceAll(
                                                                'סדנת בישול/אפיה', 'food')
                                                            .replaceAll(
                                                                'סדנת גוף/נפש',
                                                                'body-mind')
                                                            .replaceAll(
                                                                'סדנת יצירה',
                                                                'workshop')
                                                            .replaceAll(
                                                                'פעילות לילדים',
                                                                'kids');
                                                        application
                                                                .filterCategoryProvider =
                                                            realValue;

                                                        print(
                                                            '----------------------------------------');
                                                        print(selectedDropItems
                                                            .length);
                                                        print(selectedDropItems
                                                            .toString()
                                                            .replaceAll('[', '')
                                                            .replaceAll(']', '')
                                                            .replaceAll(
                                                                ', ', ','));
                                                      } else {
                                                        print(
                                                            'elseeeeeeeeeeeeeee');
                                                        // print(e);
                                                        selectedDropItems
                                                            .remove(dropItems[
                                                                index]);
                                                        print(selectedDropItems
                                                            .length);
                                                        String realValue = selectedDropItems
                                                            .toString()
                                                            .replaceAll('[', '')
                                                            .replaceAll(']', '')
                                                            .replaceAll(
                                                                ', ', ',')
                                                            .replaceAll(
                                                                'הרצאה', 'lecture')
                                                            .replaceAll(
                                                                'אירוח קולינרי',
                                                                'meals')
                                                            .replaceAll(
                                                                'הופעה/מופע', 'show')
                                                            .replaceAll(
                                                                'מפגש חברתי',
                                                                'group')
                                                            .replaceAll(
                                                                'סדנת בישול/אפיה', 'food')
                                                            .replaceAll(
                                                                'סדנת גוף/נפש',
                                                                'body-mind')
                                                            .replaceAll(
                                                                'סדנת יצירה',
                                                                'workshop')
                                                            .replaceAll(
                                                                'פעילות לילדים',
                                                                'kids');
                                                        print(
                                                            'realValue realValue realValue realValue');
                                                        print(realValue);
                                                        application
                                                                .filterCategoryProvider =
                                                            realValue;
                                                      }
                                                    });
                                                  },
                                                  title: Transform.translate(
                                                    offset: Offset(20, 0),
                                                    child: Text(
                                                      '${dropItems[index]}',
                                                      textDirection:
                                                          TextDirection.rtl,
                                                      style: dropItemsHandler[
                                                                  index] ==
                                                              true
                                                          ? ktextStyleWhite
                                                          : ktextStyle,

                                                      // TextStyle(
                                                      //     color: textColor,
                                                      //     fontSize: 16),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            itemCount: dropItems.length,
                                          ),
                                        ),
                                        Directionality(
                                          textDirection: TextDirection.rtl,
                                          child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 30),
                                                child: ReceivingPaymentFields(
                                                  controller:
                                                      categorySearchController,
                                                  obscureText: false,
                                                  width: width / 2,
                                                  hintText: 'חיפוש חופשי',
                                                  textColor: Colors.grey,
                                                ),
                                              )),
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        CustomButton(
                                            text: 'סיימתי, תראו לי מה יש לכם',
                                            onPressed: () {
                                              setState(() {
                                                showToolBar = !showToolBar;
                                                page = 1;
                                                filterByAnywhere = "";
                                              });
                                            },
                                            color: MyColors.dropdownColor),
                                        SizedBox(
                                          height: 10,
                                        )
                                      ],
                                    ),
                                  )),
                            // if (application.searchResult != null &&
                            //     application.searchResult?.length != 0
                            //     &&
                            //     application.filterAnywhereProvider ==
                            //         'עיר מסויימת' &&
                            //     locationController.text.isNotEmpty
                            // )
                            //   Container(
                            //     margin: EdgeInsets.symmetric(horizontal: 8),
                            //     decoration: const BoxDecoration(
                            //       color: Colors.white,
                            //       boxShadow: [
                            //         BoxShadow(
                            //           color: Colors.grey,
                            //           blurRadius: 15.0,
                            //           // soften the shadow
                            //           spreadRadius: 1.0,
                            //           //extend the shadow
                            //           offset: Offset(
                            //             15.0,
                            //             // Move to right 10  horizontally
                            //             15.0, // Move to bottom 10 Vertically
                            //           ),
                            //         )
                            //       ],
                            //     ),
                            //     height: 150,
                            //     // width: double.infinity,
                            //
                            //     child: ListView.separated(
                            //         padding: const EdgeInsets.all(0),
                            //         separatorBuilder: (context, index) =>
                            //             const Divider(
                            //               color: Colors.grey,
                            //             ),
                            //         itemCount: application.searchResult!.length,
                            //         itemBuilder: (context, index) {
                            //           translator
                            //               .translate(
                            //                   application.searchResult?[index]
                            //                       .description,
                            //                   to: 'iw')
                            //               .then((value) {
                            //             translatedData = value;
                            //           });
                            //
                            //           return ListTile(
                            //             dense: true,
                            //             contentPadding:
                            //                 const EdgeInsets.symmetric(
                            //                     vertical: 0, horizontal: 10),
                            //             trailing: Icon(Icons.location_on),
                            //             onTap: () async {
                            //               print('list tile dabao');
                            //
                            //               print(application.previewLatProvider);
                            //               print(application.previewLngProvider);
                            //
                            //               locationController.text = application
                            //                   .searchResult?[index].description;
                            //               application.setSelectedLocation(
                            //                   application.searchResult![index]
                            //                       .placeId);
                            //               setState(() {});
                            //             },
                            //             title: translatedData == null
                            //                 ? CupertinoActivityIndicator()
                            //                 : Text(
                            //                     "${application.searchResult?[index].description}",
                            //                     // "$translatedData",
                            //                     style: TextStyle(
                            //                         color: Colors.black,
                            //                         fontSize: 11),
                            //                     textDirection:
                            //                         TextDirection.rtl,
                            //                     textAlign: TextAlign.start,
                            //                   ),
                            //           );
                            //         }),
                            //   ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return SizedBox(
                          height: 20,
                        );
                      },
                      childCount: 1, // 1000 list items
                    ),
                  ),
                  // SliverList(
                  //   delegate: SliverChildBuilderDelegate(
                  //     (BuildContext context, int index) {
                  //       return Container(
                  //         margin: const EdgeInsets.symmetric(horizontal: 30.0),
                  //         child: Column(
                  //           mainAxisAlignment: MainAxisAlignment.start,
                  //           crossAxisAlignment: CrossAxisAlignment.end,
                  //           children: [
                  //             Text(
                  //               'רדיוס: ${radiusVal} ק"מ',
                  //               // 'Radius: ${radiusVal}km',
                  //               style: const TextStyle(
                  //                 fontSize: 15,
                  //                 fontWeight: FontWeight.w500,
                  //               ),
                  //             ),
                  //             AdvancedSeekBar(
                  //               Colors.grey,
                  //               15,
                  //               MyColors.topOrange,
                  //               lineHeight: 3,
                  //               defaultProgress: 50,
                  //               scaleWhileDrag: true,
                  //               // percentSplit: 10,
                  //               percentSplitColor: MyColors.homeBackGroundColor,
                  //               percentSplitWidth: 1,
                  //               seekBarStarted: () {},
                  //               seekBarProgress: (v) {},
                  //               seekBarFinished: (v) {
                  //                 print(v);
                  //                 setState(() {
                  //                   radiusVal = v;
                  //                 });
                  //               },
                  //             ),
                  //           ],
                  //         ),
                  //       );
                  //     },
                  //     childCount: 1, // 1000 list items
                  //   ),
                  // ),

                  (snapshot.connectionState == ConnectionState.waiting &&
                          page <= 1)
                      ? SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              return Center(
                                child: Image.asset(
                                  'assets/loader/loaderNew.gif',
                                  height: 50,
                                  width: 50,
                                ),
                              );
                            },
                            childCount: 1,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              final items = _fetchEventData.data;
                              if (snapshot.data.length == 0 &&
                                  snapshot.connectionState ==
                                      ConnectionState.done) {
                                return Text('data');
                              } else {
                                return EventCard(
                                  datum: items[index],
                                  email: _updateAndGetUserProfile
                                      .getUserData?.data?.authorEmail,
                                  name: _updateAndGetUserProfile
                                      .getUserData?.data?.displayName,
                                );
                              }
                            },
                            childCount: snapshot.data.length,
                          ),
                        ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return const SizedBox(
                          height: 20,
                        );
                      },
                      childCount: 1, // 1000 list items
                    ),
                  ),
                ],
              ),
            );

            // return Center(child: Text('Loading...'));
          },
        ),
        bottomNavigationBar: Stack(
          alignment: Alignment.bottomLeft,
          // mainAxisAlignment: MainAxisAlignment.end,
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showToolBarRow)
              Container(
                // height: 350,
                margin: EdgeInsets.only(bottom: 60),
                padding: EdgeInsets.only(top: 15),
                width: 250,
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'ניתן לבחור יותר מקטגוריה אחת',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Column(children: [
                      ListView.builder(
                        itemBuilder: (context, index) {
                          return Container(
                            color: dropItemsHandler[index] == true
                                ? MyColors.topOrange
                                : Colors.white,
                            margin: EdgeInsets.only(bottom: 2),
                            child: CheckboxListTile(
                              selectedTileColor: Colors.red,
                              selected: dropItemsHandler[index],
                              side: BorderSide(
                                width: 0.5,
                                color: Colors.grey,
                              ),
                              visualDensity: VisualDensity.lerp(
                                  VisualDensity.compact,
                                  VisualDensity.compact,
                                  0.0),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              activeColor: MyColors.topOrange,
                              value: selectedDropItems
                                  .toString()
                                  .toLowerCase()
                                  .contains(
                                      '${dropItems[index].toString().toLowerCase()}'),
                              onChanged: (value) {
                                dropTextColorHandler = value;
                                dropItemsHandler[index] = value!;
                                print(value);
                                setState(() {
                                  if (value == true) {
                                    print('iffffffffffffff');
                                    // print(selectedDropItems
                                    //     .indexOf(e));

                                    // print(e);
                                    // dropText = e;

                                    selectedDropItems.add(dropItems[index]);
                                    String realValue = selectedDropItems
                                        .toString()
                                        .replaceAll('[', '')
                                        .replaceAll(']', '')
                                        .replaceAll(', ', ',')
                                        .replaceAll('הרצאה', 'lecture')
                                        .replaceAll('אירוח קולינרי', 'meals')
                                        .replaceAll('הופעה/מופע', 'show')
                                        .replaceAll('מפגש חברתי', 'group')
                                        .replaceAll('סדנת בישול/אפיה', 'food')
                                        .replaceAll('סדנת גוף/נפש', 'body-mind')
                                        .replaceAll('סדנת יצירה', 'workshop')
                                        .replaceAll('פעילות לילדים', 'kids');
                                    application.filterCategoryProvider =
                                        realValue;
                                    print(selectedDropItems);
                                    print(selectedDropItems
                                        .toString()
                                        .replaceAll('[', '')
                                        .replaceAll(']', '')
                                        .replaceAll(', ', ','));
                                  } else {
                                    print('elseeeeeeeeeeeeeee');
                                    // print(e);
                                    selectedDropItems.remove(dropItems[index]);
                                    print(selectedDropItems);
                                    String realValue = selectedDropItems
                                        .toString()
                                        .replaceAll('[', '')
                                        .replaceAll(']', '')
                                        .replaceAll(', ', ',')
                                        .replaceAll('הרצאה', 'lecture')
                                        .replaceAll('אירוח קולינרי', 'meals')
                                        .replaceAll('הופעה/מופע', 'show')
                                        .replaceAll('מפגש חברתי', 'group')
                                        .replaceAll('סדנת בישול/אפיה', 'food')
                                        .replaceAll('סדנת גוף/נפש', 'body-mind')
                                        .replaceAll('סדנת יצירה', 'workshop')
                                        .replaceAll('פעילות לילדים', 'kids');
                                    print(
                                        'realValue realValue realValue realValue');
                                    print(realValue);
                                    application.filterCategoryProvider =
                                        realValue;
                                  }
                                });
                              },
                              title: Transform.translate(
                                offset: Offset(20, 0),
                                child: Text(
                                  '${dropItems[index]}',
                                  textDirection: TextDirection.rtl,
                                  style: dropItemsHandler[index] == true
                                      ? ktextStyleWhite
                                      : ktextStyle,

                                  // TextStyle(
                                  //     color: textColor,
                                  //     fontSize: 16),
                                ),
                              ),
                            ),
                          );
                        },
                        itemCount: dropItems.length,
                        shrinkWrap: true,
                      ),
                    ]),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ReceivingPaymentFields(
                          controller: categorySearchController,
                          obscureText: false,
                          // width: 130,
                          height: 40,
                          hintText: 'חיפוש חופשי',
                          textColor: Colors.grey,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: CustomButton(
                          width: width,
                          text: 'סיימתי, תראו לי מה יש לכם',
                          textStyle:
                              TextStyle(fontSize: 14, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              showToolBarRow = !showToolBarRow;
                              page = 1;
                            });
                          },
                          color: MyColors.dropdownColor),
                    ),
                  ],
                ),
              ),
            ScrollToHide(
              scrollViewController: _scrollViewController,
              child: Column(
                children: [
                  if (application.filterTimeProvider == 'specific_date')
                  // application.filterTimeProvider = 'this_week',
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Container(
                        // height: 170,
                        margin: EdgeInsets.only(right: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ReceivingPaymentFields(
                              hintText: 'החל מתאריך...',
                              textColor: Colors.white,
                              width: 130,
                              colors: MyColors.dropdownColor,
                              obscureText: false,
                              controller: startDateController,
                              textColorPrimary: Colors.white,
                              onTap: () async {
                                var date = await selectDate(
                                    isDob: true, context: context);
                                if (date != "null") {
                                  setState(() {
                                    startDateController.text =
                                        convertSingleDate(date);
                                  });
                                }
                              },
                            ),
                            SizedBox(width: 10),
                            ReceivingPaymentFields(
                              hintText: 'עד תאריך...',
                              textColor: Colors.white,
                              textColorPrimary: Colors.white,
                              width: 130,
                              colors: MyColors.dropdownColor,
                              obscureText: false,
                              controller: endDateController,
                              onTap: () async {
                                var date = await selectDate(
                                    isDob: true, context: context);
                                if (date != "null") {
                                  setState(() {
                                    endDateController.text =
                                        convertSingleDate(date);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    color: MyColors.dropdownColor.withOpacity(1),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showToolBarRow = !showToolBarRow;
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(left: 5),
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            color: MyColors.dropdownColor,
                            // height: 50,
                            // width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                ),
                                Column(
                                  children: [
                                    Text(
                                      'מה?',
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    RichText(
                                      textDirection: TextDirection.rtl,
                                      text: TextSpan(
                                        text:
                                            '${selectedDropItems.isNotEmpty ? selectedDropItems.length : ''} ',
                                        style: ktextStyleSmallWhite,
                                        children: [
                                          TextSpan(
                                              text: selectedDropItems.isEmpty
                                                  ? 'כל החוויות'
                                                  : 'נבחרו',
                                              style: ktextStyleSmallWhite),
                                        ],
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          child: DropButtonByTime(
                            text1: 'מתי?',
                            text2: 'בכל עת',
                            onChanged: (value) {
                              setState(() {
                                filterByTime = value;
                                application.filterTimeProvider = value;
                                page = 1;
                                showToolBarRow = false;
                              });
                            },
                          ),
                        ),
                        DropButtonByAnywhere(
                          text1: 'איפה?',
                          text2: 'כל החוויות',
                          onChanged: (value) {
                            print(
                                'value from value from value from value from ');
                            print(value);
                            setState(() {
                              application.filterAnywhereProvider = value
                                  .toString()
                                  .replaceAll('אונליין / זום', 'online');
                              application.showOnline = !showOnline;
                              page = 1;
                            });
                            if (value == 'בכל מקום') {
                              print('chli kya condition ??????????/');
                              setState(() {
                                application.filterCategoryProvider = '';
                                // application.filterTimeProvider =
                                //     '';
                                application.filterAnywhereProvider = 'בכל מקום';
                                categorySearchController.text = '';
                                endDateController.text = '';
                                startDateController.text = '';
                                klatitude = null;
                                klongitude = null;
                                page = 1;
                              });
                            }
                            if (value == 'קרוב אליי') {
                              klatitude = null;
                              klongitude = null;
                            }
                            if (value == 'עיר מסויימת') {
                              _scrollViewController.position.restoreOffset(0.0);
                            }
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: showToolBarRow != true
            ? Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: ScrollToHide(
                  scrollViewController: _scrollViewController,
                  child: Container(
                    height: 80,
                    width: 80,
                    child: FloatingActionButton(
                      backgroundColor: Colors.transparent,
                      onPressed: () async {
                        if (_fetchEventData.data.isNotEmpty) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapSample(
                                lat: application.mapLat,
                                lng: application.mapLog,
                                eventCoordinates: _fetchEventData.data,
                                currentLocation: geoLoc,
                                emailFromHome: _updateAndGetUserProfile
                                    .getUserData?.data?.authorEmail,
                              ),
                            ),
                          );
                        }
                        print('location floating');
                      },
                      child: Image.asset(
                        'assets/icons/map.png',
                        fit: BoxFit.fill,
                        height: 100,
                        width: 100,
                      ),
                    ),
                  ),
                ),
              )
            : SizedBox(),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniStartDocked,
      ),
    );
  }

  final Completer<GoogleMapController> _mapController = Completer();
  dynamic klatitude;
  dynamic klongitude;

  Future<void> _goToPlace(place) async {
    print('ye rhi place');
    print(place.lat);
    print(place.lng);
    setState(() {
      klatitude = place.lat;
      klongitude = place.lng;
    });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {});
    });
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(place.lat, place.lng), zoom: 15),
      ),
    );
  }
}
