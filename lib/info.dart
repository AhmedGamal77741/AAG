import 'package:AAG/card_info.dart';
import 'package:flutter/material.dart';
List<CardInfo>guides=[
  CardInfo(title:'Eating',subtitle:'aaaaap'),
  CardInfo(title:'Drinking',subtitle:'yeee'),
  CardInfo(title:'Bath',subtitle:'onnnnm'),
  CardInfo(title:'Tired',subtitle:'offfffff'),
  CardInfo(title:'Sleeping',subtitle:'oooooo'),
 
];
class Info extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text('Info'),
        centerTitle:true,
      ),
      body: ListView.builder(
       itemCount: guides.length,
       itemBuilder: (context,index){
         return Padding(
           padding:  const EdgeInsets.symmetric(vertical: 1.0,horizontal: 4.0),
           child: Card(
             child:ListTile(
               title: Text(guides[index].title),
               subtitle:Text(guides[index].subtitle) ,
             ),
           ),
           );
       }
       ),
    );
  }
}