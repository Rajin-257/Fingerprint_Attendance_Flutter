import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../data/local/database_helper.dart';
import '../../../utils/snackbar_utils.dart';

class InstituteListScreen extends StatefulWidget {
  const InstituteListScreen({super.key});

  @override
  State<InstituteListScreen> createState() => _InstituteListScreenState();
}

class _InstituteListScreenState extends State<InstituteListScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _institutes = [];
  String _searchQuery = '';
  
  final _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadInstitutes();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Load institutes
  Future<void> _loadInstitutes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Load all institutes
      final institutes = await dbHelper.query(
        'institutes',
        where: 'active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      
      if (mounted) {
        setState(() {
          _institutes = institutes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to load institutes: ${e.toString()}');
      }
    }
  }
  
  // Filter institutes by search query
  void _filterInstitutes() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }
  
  // View institute details
  void _viewInstituteDetails(Map<String, dynamic> institute) {
    Navigator.pushNamed(
      context,
      AppRoutes.instituteDetails,
      arguments: institute,
    );
  }
  
  // Build institute list item
  Widget _buildInstituteItem(Map<String, dynamic> institute) {
    final name = institute['name'];
    final code = institute['code'];
    final address = institute['address'];
    final isActive = institute['active'] == 1;
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: InkWell(
        onTap: () => _viewInstituteDetails(institute),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Institute icon
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  name.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Institute info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      code,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (address != null && address.toString().isNotEmpty)
                      Text(
                        address,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              // Status and action
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => _viewInstituteDetails(institute),
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Filter institutes based on search query
    final filteredInstitutes = _searchQuery.isEmpty
        ? _institutes
        : _institutes.where((institute) {
            final name = institute['name'].toString().toLowerCase();
            final code = institute['code'].toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            
            return name.contains(query) || code.contains(query);
          }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Institutes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInstitutes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search institutes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _filterInstitutes(),
            ),
          ),
          
          // Institute count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${filteredInstitutes.length} institute${filteredInstitutes.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Institute list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredInstitutes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.business_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No institutes found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a new institute to get started',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredInstitutes.length,
                        itemBuilder: (context, index) {
                          return _buildInstituteItem(filteredInstitutes[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createInstitute);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
