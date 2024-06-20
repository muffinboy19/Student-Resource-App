import 'dart:convert';

import '../components/CustomFlatButton.dart';
import 'package:circle_list/circle_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:studentresourceapp/components/custom_loader.dart';
import 'package:studentresourceapp/components/error_animatedtext.dart';
import 'package:studentresourceapp/components/navDrawer.dart';
import 'package:studentresourceapp/components/nocontent_animatedtext.dart';
import 'package:studentresourceapp/models/user.dart';
import 'package:studentresourceapp/pages/subject.dart';
import 'package:studentresourceapp/utils/contstants.dart';
import 'package:studentresourceapp/utils/sharedpreferencesutil.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  User userLoad = User();
  late ScrollController _scrollController;
  late AnimationController _hideFabAnimController;
  bool admin = false;

  Future fetchUserDetailsFromSharedPref() async {
    var result =
    await SharedPreferencesUtil.getStringValue(Constants.USER_DETAIL_OBJECT);
    if (result != null) {
      Map<String, dynamic> valueMap = json.decode(result);
      User user = User.fromJson(valueMap);
      setState(() {
        userLoad = user;
      });
    }
  }

  Future checkIfAdmin() async {
    final QuerySnapshot result =
    await FirebaseFirestore.instance.collection('admins').get();
    final List<DocumentSnapshot> documents = result.docs;
    documents.forEach((data) {
      if (data.id == userLoad.uid) {
        setState(() {
          admin = true;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchUserDetailsFromSharedPref();
    checkIfAdmin();
    _scrollController = ScrollController();
    _hideFabAnimController = AnimationController(
      vsync: this,
      duration: kThemeAnimationDuration,
      value: 1, // initially visible
    );
    _scrollController.addListener(() {
      switch (_scrollController.position.userScrollDirection) {
      // Scrolling up - forward the animation (value goes to 1)
        case ScrollDirection.forward:
          _hideFabAnimController.forward();
          break;
      // Scrolling down - reverse the animation (value goes to 0)
        case ScrollDirection.reverse:
          _hideFabAnimController.reverse();
          break;
      // Idle - keep FAB visibility unchanged
        case ScrollDirection.idle:
          break;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _hideFabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavDrawer(userData: userLoad, admin: admin),
      appBar: AppBar(
        backgroundColor: Constants.DARK_SKYBLUE,
        elevation: 0,
        bottom: PreferredSize(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Semester ${userLoad.semester ?? ''}",
                style: TextStyle(
                  fontSize: 24,
                  color: Constants.WHITE,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          preferredSize: Size.fromHeight(28),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('Semesters')
              .doc('${userLoad.semester}')
              .snapshots(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CustomLoader());
            }
            if (snapshot.hasError) {
              return Center(child: ErrorAnimatedText());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: NoContentAnimatedText());
            }

            Map<String, dynamic> branchSubjects =
            snapshot.data!.data()!['branches'][userLoad.branch.toUpperCase()];
            List<Widget> subjects = [];

            branchSubjects.forEach((key, value) {
              subjects.add(
                CustomFlatButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Subject(
                          semester: userLoad.semester,
                          subjectCode: key,
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: Image.asset(
                      'assets/images/Computer.png',
                      height: 32,
                    ),
                    title: Text(
                      key,
                      style: TextStyle(
                        color: Constants.BLACK,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      value.toString(),
                      style: TextStyle(
                        color: Constants.STEEL,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      Icons.keyboard_arrow_right,
                      color: Constants.BLACK,
                      size: 36,
                    ),
                  ),
                  splashColor: Constants.SKYBLUE, text: '',
                ),
              );
            });

            if (subjects.isEmpty) {
              return Center(child: NoContentAnimatedText());
            }

            return ListView.separated(
              controller: _scrollController,
              itemCount: subjects.length,
              separatorBuilder: (BuildContext context, int index) => Divider(
                thickness: 0.5,
                color: Constants.SMOKE,
                indent: 24,
                endIndent: 24,
              ),
              itemBuilder: (BuildContext context, int index) {
                return subjects[index];
              },
            );
          },
        ),
      ),
      floatingActionButton: FadeTransition(
        opacity: _hideFabAnimController,
        child: ScaleTransition(
          scale: _hideFabAnimController,
          child: FloatingActionButton.extended(
            backgroundColor: Constants.DARK_SKYBLUE,
            elevation: 1,
            isExtended: true,
            label: Text(
              'Switch Sem',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return CircleList(
                    showInitialAnimation: true,
                    animationSetting: AnimationSetting(
                      duration: Duration(milliseconds: 800),
                      curve: Curves.fastOutSlowIn,
                    ),
                    children: List.generate(
                      8,
                          (index) => ClipRRect(
                        borderRadius: BorderRadius.circular(1000),
                        child: MaterialButton(
                          height: 60,
                          minWidth: 60,
                          color: (index + 1) == userLoad.semester
                              ? Constants.DARK_SKYBLUE
                              : Constants.WHITE,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 36,
                              color: Constants.BLACK,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            setState(() {
                              userLoad.semester = index + 1;
                            });
                            try {
                              await SharedPreferencesUtil.setStringValue(
                                Constants.USER_DETAIL_OBJECT,
                                json.encode(userLoad.toJson()),
                              );
                              await FirebaseFirestore.instance
                                  .collection(Constants.COLLECTION_NAME_USER)
                                  .doc(userLoad.uid)
                                  .set({'semester': index + 1}, SetOptions(merge: true));
                            } catch (e) {
                              print('Error setting semester: $e');
                            }
                          },
                        ),
                      ),
                    ),
                    outerCircleColor: Constants.WHITE,
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
