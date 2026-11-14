part of 'main.dart';

/// Browser-local view history is ephemeral. No user data is persisted here.
extension _AssetViewNavigation on _AssetScreenState {
  String _viewRouteKey() =>
    page.toString() + '|' + (selected?.id ?? '') +
    '|' + (selectedEmployee?.id ?? '') +
    '|' + (selectedAssignment?.id ?? '');

  Map<String, dynamic> _captureView() => {
    'page': page,
    'assetId': selected?.id,
    'employeeId': selectedEmployee?.id,
    'assignmentId': selectedAssignment?.id,
    'scroll': _contentScroll.hasClients ? _contentScroll.offset : 0.0,
    'assetQuery': query,
    'statusFilter': statusFilter,
    'categoryFilter': categoryFilter,
    'locationFilter': v4LocationFilter,
    'locationAreaFilter': v4LocationAreaFilter,
    'locationSpotFilter': v4LocationSpotFilter,
    'conditionFilter': v4ConditionFilter,
    'noPic': v4NoPic, 'noPhoto': v4NoPhoto,
    'attention': v4Attention,
    'needsClassification': v4NeedsClassification,
    'sort': v4Sort, 'sortAsc': v4SortAscending,
    'perPage': v4PerPage, 'catalogPage': v4CatalogPage,
    'taxonomyCategory': v4CategoryCode,
    'taxonomySubcategory': v4SubcategoryId,
    'taxonomyQuery': v4TaxonomySearch,
    'locationSite': v6SiteId, 'locationArea': v6AreaId,
    'locationQuery': v6LocationSearch,
    'historyQuery': v4HistoryQuery,
    'historyType': v4HistoryType,
    'historyPeriod': v4HistoryPeriod,
    'historyPage': v4HistoryPage,
    'historyPerPage': v4HistoryPerPage,
    'employeeQuery': v5EmployeeSearch,
    'employeeFilter': v5EmployeeFilter,
    'assignmentQuery': v5AssignmentSearch,
    'assignmentFilter': v5AssignmentFilter,
    'assignmentPage': v5AssignmentPage,
    'assignmentPerPage': v5AssignmentPerPage,
  };

  void _restoreView(Map<String, dynamic> data) {
    page = data['page'] as int? ?? 1;
    selected = assetFor(data['assetId'] as String? ?? '');
    final employeeId = data['employeeId'] as String? ?? '';
    selectedEmployee = store.employeeById(employeeId);
    final assignmentId = data['assignmentId'] as String? ?? '';
    selectedAssignment = store.assignmentById(assignmentId);
    query = data['assetQuery'] as String? ?? '';
    _assetSearchController.text = query;
    statusFilter = data['statusFilter'] as String? ?? 'Semua status';
    categoryFilter = data['categoryFilter'] as String? ?? 'Semua kategori';
    v4LocationFilter = data['locationFilter'] as String? ?? 'Semua lokasi';
    v4LocationAreaFilter = data['locationAreaFilter'] as String? ?? '';
    v4LocationSpotFilter = data['locationSpotFilter'] as String? ?? '';
    v4ConditionFilter = data['conditionFilter'] as String? ?? 'Semua kondisi';
    v4NoPic = data['noPic'] as bool? ?? false;
    v4NoPhoto = data['noPhoto'] as bool? ?? false;
    v4Attention = data['attention'] as bool? ?? false;
    v4NeedsClassification = data['needsClassification'] as bool? ?? false;
    v4Sort = data['sort'] as String? ?? 'Kode';
    v4SortAscending = data['sortAsc'] as bool? ?? true;
    v4PerPage = data['perPage'] as int? ?? 20;
    v4CatalogPage = data['catalogPage'] as int? ?? 0;
    v4CategoryCode = data['taxonomyCategory'] as String? ?? '03';
    v4SubcategoryId = data['taxonomySubcategory'] as String? ?? '';
    v4TaxonomySearch = data['taxonomyQuery'] as String? ?? '';
    _taxonomySearchController.text = v4TaxonomySearch;
    v6SiteId = data['locationSite'] as String? ?? '';
    v6AreaId = data['locationArea'] as String? ?? '';
    v6LocationSearch = data['locationQuery'] as String? ?? '';
    _locationSearchController.text = v6LocationSearch;
    v4HistoryQuery = data['historyQuery'] as String? ?? '';
    _historySearchController.text = v4HistoryQuery;
    v4HistoryType = data['historyType'] as String? ?? 'Semua aktivitas';
    v4HistoryPeriod = data['historyPeriod'] as String? ?? 'Semua periode';
    v4HistoryPage = data['historyPage'] as int? ?? 0;
    v4HistoryPerPage = data['historyPerPage'] as int? ?? 20;
    v5EmployeeSearch = data['employeeQuery'] as String? ?? '';
    _employeeSearchController.text = v5EmployeeSearch;
    v5EmployeeFilter = data['employeeFilter'] as String? ?? 'Semua';
    v5AssignmentSearch = data['assignmentQuery'] as String? ?? '';
    _assignmentSearchController.text = v5AssignmentSearch;
    v5AssignmentFilter = data['assignmentFilter'] as String? ?? 'Semua';
    v5AssignmentPage = data['assignmentPage'] as int? ?? 0;
    v5AssignmentPerPage = data['assignmentPerPage'] as int? ?? 20;
  }

  void _scrollAfterRoute(double offset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_contentScroll.hasClients) return;
      final maximum = _contentScroll.position.maxScrollExtent;
      _contentScroll.jumpTo(offset.clamp(0.0, maximum).toDouble());
    });
  }

  Future<bool> _mayLeaveUnsavedForm() async {
    if (!_formDirty || ![6,9,10].contains(page)) return true;
    final response = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tinggalkan formulir?'),
        content: const Text('Ada perubahan yang belum disimpan. '
          'Jika kembali atau membuka halaman lain, isian akan hilang.'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tetap di Formulir')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tinggalkan')),
        ],
      ),
    );
    return response == true;
  }

  void markFormChanged() {
    _formDirty = true;
  }

  void replaceRouteAfterSave(VoidCallback action) {
    _restoringHistory = true;
    try {
      setState(action);
      _formDirty = false;
      _scrollAfterRoute(0);
    } finally {
      _restoringHistory = false;
    }
  }

  Future<void> backFromHistory() async {
    if (_navigationHistory.isEmpty) return;
    if (!await _mayLeaveUnsavedForm() || !mounted) return;
    final prior = _navigationHistory.removeLast();
    _restoringHistory = true;
    try {
      setState(() {
        _restoreView(prior);
        _formDirty = false;
      });
    } finally {
      _restoringHistory = false;
    }
    _scrollAfterRoute((prior['scroll'] as num?)?.toDouble() ?? 0);
  }
}
