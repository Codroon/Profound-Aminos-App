/// Utility class for mapping country names to ISO country codes
/// Required by ReachShip API for proper country code validation
class CountryCodeMapper {
  /// Map of common country names to their ISO 3166-1 alpha-2 codes
  static const Map<String, String> _countryNameToCode = {
    // Common countries
    'pakistan': 'PK',
    'united states': 'US',
    'usa': 'US',
    'united states of america': 'US',
    'canada': 'CA',
    'united kingdom': 'GB',
    'uk': 'GB',
    'great britain': 'GB',
    'england': 'GB',
    'india': 'IN',
    'china': 'CN',
    'japan': 'JP',
    'germany': 'DE',
    'france': 'FR',
    'italy': 'IT',
    'spain': 'ES',
    'australia': 'AU',
    'brazil': 'BR',
    'mexico': 'MX',
    'russia': 'RU',
    'south korea': 'KR',
    'korea': 'KR',
    'netherlands': 'NL',
    'belgium': 'BE',
    'switzerland': 'CH',
    'austria': 'AT',
    'sweden': 'SE',
    'norway': 'NO',
    'denmark': 'DK',
    'finland': 'FI',
    'poland': 'PL',
    'turkey': 'TR',
    'saudi arabia': 'SA',
    'united arab emirates': 'AE',
    'uae': 'AE',
    'south africa': 'ZA',
    'egypt': 'EG',
    'israel': 'IL',
    'thailand': 'TH',
    'singapore': 'SG',
    'malaysia': 'MY',
    'indonesia': 'ID',
    'philippines': 'PH',
    'vietnam': 'VN',
    'bangladesh': 'BD',
    'sri lanka': 'LK',
    'nepal': 'NP',
    'afghanistan': 'AF',
    'iran': 'IR',
    'iraq': 'IQ',
    'jordan': 'JO',
    'lebanon': 'LB',
    'syria': 'SY',
    'kuwait': 'KW',
    'qatar': 'QA',
    'bahrain': 'BH',
    'oman': 'OM',
    'yemen': 'YE',
    'morocco': 'MA',
    'algeria': 'DZ',
    'tunisia': 'TN',
    'libya': 'LY',
    'sudan': 'SD',
    'ethiopia': 'ET',
    'kenya': 'KE',
    'uganda': 'UG',
    'tanzania': 'TZ',
    'ghana': 'GH',
    'nigeria': 'NG',
    'cameroon': 'CM',
    'ivory coast': 'CI',
    'senegal': 'SN',
    'mali': 'ML',
    'burkina faso': 'BF',
    'niger': 'NE',
    'chad': 'TD',
    'central african republic': 'CF',
    'democratic republic of congo': 'CD',
    'congo': 'CG',
    'gabon': 'GA',
    'equatorial guinea': 'GQ',
    'sao tome and principe': 'ST',
    'cape verde': 'CV',
    'guinea-bissau': 'GW',
    'guinea': 'GN',
    'sierra leone': 'SL',
    'liberia': 'LR',
    'madagascar': 'MG',
    'mauritius': 'MU',
    'seychelles': 'SC',
    'comoros': 'KM',
    'djibouti': 'DJ',
    'eritrea': 'ER',
    'somalia': 'SO',
    'botswana': 'BW',
    'namibia': 'NA',
    'zambia': 'ZM',
    'zimbabwe': 'ZW',
    'malawi': 'MW',
    'mozambique': 'MZ',
    'swaziland': 'SZ',
    'lesotho': 'LS',
    'argentina': 'AR',
    'chile': 'CL',
    'colombia': 'CO',
    'venezuela': 'VE',
    'peru': 'PE',
    'ecuador': 'EC',
    'bolivia': 'BO',
    'paraguay': 'PY',
    'uruguay': 'UY',
    'guyana': 'GY',
    'suriname': 'SR',
    'french guiana': 'GF',
    'new zealand': 'NZ',
    'fiji': 'FJ',
    'papua new guinea': 'PG',
    'solomon islands': 'SB',
    'vanuatu': 'VU',
    'new caledonia': 'NC',
    'french polynesia': 'PF',
    'samoa': 'WS',
    'tonga': 'TO',
    'kiribati': 'KI',
    'tuvalu': 'TV',
    'nauru': 'NR',
    'palau': 'PW',
    'marshall islands': 'MH',
    'micronesia': 'FM',
  };

  /// Convert country name to ISO country code
  /// Returns the ISO code if found, otherwise returns the original input
  static String getCountryCode(String countryName) {
    if (countryName.isEmpty) return countryName;
    
    // First check if it's already a valid ISO code (2 letters)
    if (countryName.length == 2 && countryName.toUpperCase() == countryName) {
      return countryName.toUpperCase();
    }
    
    // Convert to lowercase for lookup
    final normalizedName = countryName.toLowerCase().trim();
    
    // Direct lookup
    if (_countryNameToCode.containsKey(normalizedName)) {
      return _countryNameToCode[normalizedName]!;
    }
    
    // Try partial matches for common variations
    for (final entry in _countryNameToCode.entries) {
      if (normalizedName.contains(entry.key) || entry.key.contains(normalizedName)) {
        return entry.value;
      }
    }
    
    // If no match found, return original (might be a valid ISO code already)
    return countryName.toUpperCase();
  }
  
  /// Get country name from ISO code
  static String getCountryName(String countryCode) {
    if (countryCode.isEmpty) return countryCode;
    
    final code = countryCode.toUpperCase();
    
    // Find the country name by searching for the code in values
    for (final entry in _countryNameToCode.entries) {
      if (entry.value == code) {
        // Return capitalized country name
        return entry.key.split(' ').map((word) => 
          word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)
        ).join(' ');
      }
    }
    
    return countryCode;
  }
  
  /// Check if a string is a valid ISO country code
  static bool isValidCountryCode(String code) {
    if (code.length != 2) return false;
    return _countryNameToCode.containsValue(code.toUpperCase());
  }
  
  /// Get all supported country codes
  static List<String> getAllCountryCodes() {
    return _countryNameToCode.values.toSet().toList()..sort();
  }
  
  /// Get all supported country names
  static List<String> getAllCountryNames() {
    return _countryNameToCode.keys.map((name) => 
      name.split(' ').map((word) => 
        word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)
      ).join(' ')
    ).toSet().toList()..sort();
  }
}