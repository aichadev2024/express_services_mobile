import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../models/partenaire.dart';
import '../../../models/produit.dart';
import '../../../models/quartier.dart';

/// Public read-only reference data shared by the Partenaire and Particulier
/// flows: the list of quartiers (delivery zones/pricing), partenaires
/// (identity picker), and a partenaire's own product stock.
class ReferenceDataRepository {
  final Dio _dio = DioClient.instance.dio;

  Future<List<Quartier>> getQuartiers() async {
    try {
      final response = await _dio.get('/api/quartiers');
      return (response.data as List<dynamic>)
          .map((e) => Quartier.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<Partenaire>> getPartenaires() async {
    try {
      final response = await _dio.get('/api/partenaires');
      return (response.data as List<dynamic>)
          .map((e) => Partenaire.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<Produit>> getProduitsDuPartenaire(int partenaireId) async {
    try {
      final response = await _dio.get('/api/produits', queryParameters: {
        'actifSeulement': true,
        'partenaireId': partenaireId,
      });
      return (response.data as List<dynamic>)
          .map((e) => Produit.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<Produit>> getAllProduits() async {
    try {
      final response = await _dio.get('/api/produits');
      return (response.data as List<dynamic>)
          .map((e) => Produit.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<ProduitStockStats>> getStockStats(int partenaireId) async {
    try {
      final response =
          await _dio.get('/api/produits/stats/partenaire/$partenaireId');
      return (response.data as List<dynamic>)
          .map((e) => ProduitStockStats.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
