import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../../../core/localization/app_localizations.dart';

class CommunityScreen extends StatefulWidget {
  final String cropName;

  const CommunityScreen({
    super.key,
    this.cropName = 'All',
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityService _communityService = CommunityService();

  List<CommunityPostModel> _posts = [];
  List<AgronomistExpertModel> _experts = [];
  bool _isLoading = true;
  final String _selectedCategory = 'All';


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final posts = await _communityService.getPosts(
      crop: widget.cropName != 'All' ? widget.cropName : null,
      category: _selectedCategory != 'All' ? _selectedCategory : null,
    );
    final experts = await _communityService.getExperts();

    if (mounted) {
      setState(() {
        _posts = posts;
        _experts = experts;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike(CommunityPostModel post) async {
    setState(() {
      if (post.isLiked) {
        post.likes = (post.likes > 0) ? post.likes - 1 : 0;
        post.isLiked = false;
      } else {
        post.likes += 1;
        post.isLiked = true;
      }
    });
    await _communityService.toggleLike(post.id);
  }

  void _showAddCommentSheet(CommunityPostModel post) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comments & Replies (సలహాలు / సమాధానాలు)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              if (post.comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No comments yet. Be the first to advise!'),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: post.comments.length,
                    itemBuilder: (context, idx) {
                      final c = post.comments[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  c.author,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  c.time,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(c.text, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Write a helpful reply for farmer...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.green),
                    onPressed: () async {
                      final txt = commentController.text.trim();
                      if (txt.isEmpty) return;
                      Navigator.pop(context);
                      final newComment = await _communityService.addComment(post.id, 'రైతు (Farmer)', txt);
                      if (newComment != null && mounted) {
                        setState(() {
                          post.comments.add(newComment);
                          post.commentsCount = post.comments.length;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'Question';
    String crop = widget.cropName != 'All' ? widget.cropName : 'Paddy';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Ask RythuMitra Community (ప్రశ్న అడగండి)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Topic / Question Title (శీర్షిక)',
                        hintText: 'e.g. వరిలో ఎరువుల యాజమాన్యం',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                            items: ['Question', 'Discussion', 'Scheme']
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => category = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: crop,
                            decoration: const InputDecoration(labelText: 'Crop', border: OutlineInputBorder()),
                            items: ['Paddy', 'Chilli', 'Cotton', 'Maize', 'Tomato', 'General']
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => crop = v);
                            },
                          ),
                        ),
                      ],

                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Describe the issue or tips (వివరాలు)...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final content = contentController.text.trim();
                        if (title.isEmpty || content.isEmpty) return;
                        Navigator.pop(context);
                        setState(() => _isLoading = true);
                        final newPost = await _communityService.createPost(
                          title: title,
                          crop: crop,
                          category: category,
                          content: content,
                          author: 'రైతు సోదరుడు (Farmer)',
                          location: 'ఆంధ్రప్రదేశ్',
                        );
                        if (newPost != null) {
                          _loadData();
                        } else {
                          setState(() => _isLoading = false);
                        }
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Post to Community'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.cropName != 'All' ? '${widget.cropName} Community' : 'RythuMitra Community',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3.5,
          tabs: [
            Tab(icon: const Icon(Icons.forum, size: 20), text: AppLocalizations.of(context).translate('tab_discussions')),
            Tab(icon: const Icon(Icons.verified, size: 20), text: AppLocalizations.of(context).translate('tab_schemes')),
            Tab(icon: const Icon(Icons.support_agent, size: 20), text: AppLocalizations.of(context).translate('tab_agronomists')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsList(filterCategory: 'Discussion'),
          _buildPostsList(filterCategory: 'Scheme'),
          _buildExpertsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostDialog,
        backgroundColor: Colors.green.shade800,
        icon: const Icon(Icons.add_comment, color: Colors.white),
        label: Text(AppLocalizations.of(context).translate('ask_question'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPostsList({String? filterCategory}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    final filtered = filterCategory == null
        ? _posts
        : filterCategory == 'Scheme'
            ? _posts.where((p) => p.category.toLowerCase() == 'scheme').toList()
            : _posts.where((p) => p.category.toLowerCase() != 'scheme').toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No community posts here yet.'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showCreatePostDialog,
              child: const Text('Be the first to share or ask!'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: filtered.length,
      itemBuilder: (context, idx) {
        final post = filtered[idx];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(CommunityPostModel post) {
    final isScheme = post.category.toLowerCase() == 'scheme';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info & badge
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isScheme ? Colors.purple.shade100 : Colors.green.shade100,
                  foregroundColor: isScheme ? Colors.purple.shade800 : Colors.green.shade800,
                  child: Icon(isScheme ? Icons.account_balance : Icons.person),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.author,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isScheme ? Colors.purple.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isScheme ? Colors.purple.shade300 : Colors.green.shade300,
                              ),
                            ),
                            child: Text(
                              post.crop,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isScheme ? Colors.purple.shade800 : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${post.location} • ${post.time}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title & Content
            Text(
              post.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              post.content,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.4),
            ),

            // AI Agronomist Verified Tip Card
            if (post.aiVerifiedTip != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.aiVerifiedTip!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 24),

            // Engagement Row (Likes, Comments, Share)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () => _toggleLike(post),
                  icon: Icon(
                    post.isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                    color: post.isLiked ? Colors.green.shade800 : Colors.grey.shade700,
                    size: 18,
                  ),
                  label: Text(
                    '${post.likes}',
                    style: TextStyle(
                      color: post.isLiked ? Colors.green.shade800 : Colors.grey.shade700,
                      fontWeight: post.isLiked ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddCommentSheet(post),
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 18),
                  label: Text(
                    '${post.commentsCount} Replies',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post link copied to share with farmers!')),
                    );
                  },
                  icon: const Icon(Icons.share, color: Colors.grey, size: 18),
                  tooltip: 'Share',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpertsList() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Expert Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade800, Colors.teal.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.support_agent, color: Colors.white, size: 40),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agricultural Extension Support',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Consult certified agronomists and KVK plant protection specialists for farm issues.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ..._experts.map((exp) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.green.shade100,
                          foregroundColor: Colors.green.shade800,
                          child: const Icon(Icons.person, size: 30),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                exp.title,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${exp.rating} • ${exp.experience}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Specialization: ${exp.specialization}', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('Hours: ${exp.availableHours}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Calling ${exp.name} at ${exp.phone ?? "Helpline"}...'),
                              backgroundColor: Colors.green.shade800,
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone),
                        label: Text('Contact Specialist (${exp.phone ?? "Helpline"})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
