class MockClosetService {
  /// Devuelve una lista de prendas simuladas simulando lo que vendría de Supabase
  List<Map<String, dynamic>> getMockClothes() {
    return [
      {
        'id': '1',
        'name': 'Camisa Oxford de algodón',
        'color': 'Blanco',
        'type': 'Camisa',
        'style': 'Formal/Smart Casual'
      },
      {
        'id': '2',
        'name': 'Pantalón de vestir',
        'color': 'Azul marino',
        'type': 'Pantalón',
        'style': 'Formal'
      },
      {
        'id': '3',
        'name': 'Chaqueta de cuero',
        'color': 'Negro',
        'type': 'Chaqueta',
        'style': 'Urbano/Casual'
      },
      {
        'id': '4',
        'name': 'Jeans ajustados',
        'color': 'Gris oscuro',
        'type': 'Pantalón',
        'style': 'Casual'
      },
      {
        'id': '5',
        'name': 'Zapatillas deportivas',
        'color': 'Blanco',
        'type': 'Zapatos',
        'style': 'Urbano/Deportivo'
      },
      {
        'id': '6',
        'name': 'Zapatos Oxford de piel',
        'color': 'Marrón oscuro',
        'type': 'Zapatos',
        'style': 'Formal'
      },
    ];
  }
}
