/// 일정 레포지토리 구현. 원격 데이터소스 위임.
library;
import 'dart:io' if (dart.library.html) 'package:travel_mate_app/core/io_stub/file_stub.dart';

import 'package:travel_mate_app/data/datasources/itinerary_remote_datasource.dart';
import 'package:travel_mate_app/data/models/itinerary_model.dart';
import 'package:travel_mate_app/domain/entities/itinerary.dart';
import 'package:travel_mate_app/domain/repositories/itinerary_repository.dart';

class ItineraryRepositoryImpl implements ItineraryRepository {
  final ItineraryRemoteDataSource remoteDataSource;

  ItineraryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Itinerary>> getItineraries() async {
    return await remoteDataSource.getItineraries();
  }

  @override
  Future<Itinerary> getItinerary(String itineraryId) async {
    return await remoteDataSource.getItinerary(itineraryId);
  }

  @override
  Future<void> createItinerary(Itinerary itinerary) async {
    if (itinerary is ItineraryModel) {
      await remoteDataSource.createItinerary(itinerary);
    } else {
      await remoteDataSource.createItinerary(ItineraryModel(
        id: itinerary.id,
        authorId: itinerary.authorId,
        title: itinerary.title,
        description: itinerary.description,
        startDate: itinerary.startDate,
        endDate: itinerary.endDate,
        imageUrls: itinerary.imageUrls,
        mapData: itinerary.mapData,
        createdAt: itinerary.createdAt,
        updatedAt: itinerary.updatedAt,
      ));
    }
  }

  @override
  Future<void> updateItinerary(Itinerary itinerary) async {
    if (itinerary is ItineraryModel) {
      await remoteDataSource.updateItinerary(itinerary);
    } else {
      await remoteDataSource.updateItinerary(ItineraryModel(
        id: itinerary.id,
        authorId: itinerary.authorId,
        title: itinerary.title,
        description: itinerary.description,
        startDate: itinerary.startDate,
        endDate: itinerary.endDate,
        imageUrls: itinerary.imageUrls,
        mapData: itinerary.mapData,
        createdAt: itinerary.createdAt,
        updatedAt: itinerary.updatedAt,
      ));
    }
  }

  @override
  Future<void> deleteItinerary(String itineraryId) async {
    await remoteDataSource.deleteItinerary(itineraryId);
  }

  @override
  Future<String> uploadItineraryImage(String userId, String imagePath) async {
    return await remoteDataSource.uploadItineraryImage(userId, File(imagePath));
  }
}
