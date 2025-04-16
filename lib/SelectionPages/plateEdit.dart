import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plate_ocr/SelectionPages/parkingList.dart';
import 'package:plate_ocr/SelectionPages/parkingTimeChoice.dart';



class CarInfo {
  String plateNumber;
  String model;
  File? image;

  CarInfo({required this.plateNumber, required this.model, this.image});
}

class LicensePlateListPage extends StatefulWidget {

  final Parking parking;
  const LicensePlateListPage({super.key, required this.parking});

  @override
  _LicensePlateListPageState createState() => _LicensePlateListPageState();
}

class _LicensePlateListPageState extends State<LicensePlateListPage> {
  List<CarInfo> carList = [];
  void _navigateToEdit({CarInfo? car, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditCarPage(car: car),
      ),
    );

    if (result != null && result is CarInfo) {
      setState(() {
        if (index != null) {
          carList[index] = result;
        } else {
          carList.add(result);
        }
      });
    }
  }

  void _navigateToPayment(String plateNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParkingTimeScreen(plateNumber: plateNumber, parking: widget.parking,),
      ),
    );
  }

  void _deleteCar(int index) {
    setState(() {
      carList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Car Plate Management')),
      body: ListView.builder(
        itemCount: carList.length,
        itemBuilder: (context, index) {
          final car = carList[index];
          return Card(
            child: ListTile(
              leading: car.image != null
                  ? Image.file(car.image!, width: 50, height: 50, fit: BoxFit.cover)
                  : Container(width: 50, height: 50, color: Colors.grey),
              title: Text(car.plateNumber),
              subtitle: Text(car.model),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.payment),
                    onPressed: () => _navigateToPayment(car.plateNumber),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _navigateToEdit(car: car, index: index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteCar(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _navigateToEdit(),
      ),
    );
  }
}

class EditCarPage extends StatefulWidget {
  final CarInfo? car;

  const EditCarPage({Key? key, this.car}) : super(key: key);

  @override
  _EditCarPageState createState() => _EditCarPageState();
}

class _EditCarPageState extends State<EditCarPage> {
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();
    if (widget.car != null) {
      _plateController.text = widget.car!.plateNumber;
      _modelController.text = widget.car!.model;
      _image = widget.car!.image;
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  void _save() {
    if (_plateController.text.isEmpty || _modelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    final car = CarInfo(
      plateNumber: _plateController.text,
      model: _modelController.text,
      image: _image,
    );
    Navigator.pop(context, car);
  }

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.car == null ? 'Add Car' : 'Edit Car'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _plateController,
              decoration: InputDecoration(labelText: 'Plate Number'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _modelController,
              decoration: InputDecoration(labelText: 'Car Model'),
            ),
            SizedBox(height: 20),
            _image != null
                ? Image.file(_image!, height: 150)
                : Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[300],
              child: Center(child: Text('No photo')),
            ),
            TextButton.icon(
              icon: Icon(Icons.photo),
              label: Text('Upload a photo'),
              onPressed: _pickImage,
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
