import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:studentresourceapp/components/custom_loader.dart';
import 'package:studentresourceapp/pages/subjects_admin.dart';

class Admin extends StatefulWidget {
  Admin({this.uid});

  final uid;

  @override
  _AdminState createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  bool canManageModerators = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkModeratorManageAccess();
  }

  Future<void> checkModeratorManageAccess() async {
    try {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('admins')
          .get();

      final List<DocumentSnapshot> documents = result.docs;
      documents.forEach((data) {
        final Map<String, dynamic>? adminData = data.data() as Map<String, dynamic>?;

        if (adminData != null && adminData.containsKey('canManageModerators') && adminData['canManageModerators'] == true &&
            data.id == widget.uid) {
          setState(() {
            canManageModerators = true;
          });
        }
      });
    } catch (error) {
      print('Error retrieving admin data: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin'),
      ),
      body: isLoading
          ? CustomLoader()
          : StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('admins')
            .doc(widget.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasData) {
            try {
              List<dynamic> subjectAssigned =
                  (snapshot.data!.data() as Map<String, dynamic>?)?['subjects_assigned'] ?? [];
              List<Widget> listMaterials = subjectAssigned
                  .map((element) => Padding(
                padding: const EdgeInsets.only(
                    right: 16, left: 16, top: 12),
                child: Card(
                  shadowColor: Color.fromRGBO(0, 0, 0, 0.75),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(element.toString()),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                              SubjectsAdmin(
                                subjectCode: element.toString(),
                                canManageModerators: canManageModerators,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ))
                  .toList();

              listMaterials.add(SizedBox(height: 100));
              return ListView(
                children: listMaterials,
              );
            } catch (error) {
              print('Error building subject list: $error');
              return Center(child: Text('Error building subject list'));
            }
          } else if (snapshot.hasError) {
            print('Snapshot error: ${snapshot.error}');
            return Center(child: Text('Snapshot error'));
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}
