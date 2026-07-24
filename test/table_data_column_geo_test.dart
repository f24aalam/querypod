import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/editor/domain/entities/table_data.dart';

void main() {
  test('infers common latitude and longitude column names', () {
    expect(_column('lat').effectiveGeoKind, TableColumnGeoKind.latitude);
    expect(_column('latitude').effectiveGeoKind, TableColumnGeoKind.latitude);
    expect(_column('lon').effectiveGeoKind, TableColumnGeoKind.longitude);
    expect(_column('lng').effectiveGeoKind, TableColumnGeoKind.longitude);
    expect(_column('longitude').effectiveGeoKind, TableColumnGeoKind.longitude);
    expect(_column('name').effectiveGeoKind, TableColumnGeoKind.none);
  });

  test('explicit PostGIS metadata takes precedence over name inference', () {
    const column = TableDataColumn(
      name: 'location',
      databaseType: 'geometry',
      length: 0,
      isPrimaryKey: false,
      isNullable: true,
      geoKind: TableColumnGeoKind.geometry,
      srid: 4326,
    );

    expect(column.effectiveGeoKind, TableColumnGeoKind.geometry);
    expect(column.srid, 4326);
    expect(column.isGeoColumn, isTrue);
  });
}

TableDataColumn _column(String name) {
  return TableDataColumn(
    name: name,
    databaseType: 'text',
    length: 0,
    isPrimaryKey: false,
    isNullable: true,
  );
}
