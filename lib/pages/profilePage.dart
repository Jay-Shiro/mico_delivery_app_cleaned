import 'package:flutter/material.dart';
import 'package:micollins_delivery_app/components/mico_list_tiles.dart';
import 'package:path/path.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: SafeArea(
            child: Container(
                height: MediaQuery.sizeOf(context).height * 0.9,
                width: MediaQuery.sizeOf(context).width,
                child: Scaffold(body: profileUi()))));
  }
}

Widget profileUi() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [title(), mainsection()],
  );
}

Widget title() {
  return Column(
    children: [
      Text(
        'MY PROFILE',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const SizedBox(
        height: 18,
      ),
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Color.fromRGBO(227, 223, 214, 1),
          radius: 32,
          child: Image.asset(
            'assets/images/profilepic.png',
          ),
        ),
        title: Text(
          '<Username>',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '<email.address@gmail.com>',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      )
    ],
  );
}

Widget mainsection() {
  return Container(
    width: 390,
    height: 580,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadiusDirectional.all(
        Radius.circular(40),
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MicoListTiles(
          leading: Image.asset(
            'assets/images/profile.png',
            scale: 20,
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          trailing: Icon(Icons.arrow_forward),
        ),
        const SizedBox(
          height: 25,
        ),
        MicoListTiles(
          leading: Image.asset(
            'assets/images/notification.png',
            scale: 20,
          ),
          title: Text(
            'Notification',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          trailing: Icon(Icons.arrow_forward),
        ),
        const SizedBox(
          height: 25,
        ),
        MicoListTiles(
          leading: Image.asset(
            'assets/images/payment.png',
            scale: 20,
          ),
          title: Text(
            'Payment',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          trailing: Icon(Icons.arrow_forward),
        ),
        const SizedBox(
          height: 25,
        ),
        MicoListTiles(
          leading: Image.asset(
            'assets/images/security.png',
            scale: 20,
          ),
          title: Text(
            'Security',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          trailing: Icon(Icons.arrow_forward),
        ),
        const SizedBox(
          height: 25,
        ),
        MicoListTiles(
          leading: Image.asset(
            'assets/images/invite.png',
            scale: 20,
          ),
          title: Text(
            'Invite friends',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          trailing: Icon(Icons.arrow_forward),
        ),
        const SizedBox(
          height: 25,
        ),
        MicoListTiles(
          leading: Image.asset(
            'assets/images/logout.png',
            scale: 20,
          ),
          title: Text(
            'Log out',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color.fromRGBO(255, 114, 0, 1),
            ),
          ),
          trailing: Icon(Icons.arrow_forward),
        ),
      ],
    ),
  );
}
