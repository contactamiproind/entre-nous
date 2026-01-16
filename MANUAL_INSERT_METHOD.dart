// INSTRUCTION: Copy the _loadCategoryProgress method below and paste it into
// enhanced_user_dashboard.dart at line 191 (right after the _logout method and before @override)

  Future<void> _loadCategoryProgress() async {
    if (_userId == null) return;
    
    try {
      final categories = ['Orientation', 'Process', 'SOP'];
      
      for (final category in categories) {
        final deptData = await Supabase.instance.client
            .from('departments')
            .select('id')
            .eq('title', category)
            .maybeSingle();
        
        if (deptData == null) continue;
        
        final deptId = deptData['id'];
        
        final usrDeptData = await Supabase.instance.client
            .from('usr_dept')
            .select('id')
            .eq('user_id', _userId!)
            .eq('dept_id', deptId)
            .maybeSingle();
        
        if (usrDeptData == null) {
          _categoryProgress[category] = {
            'total': 0,
            'answered': 0,
            'firstUnansweredIndex': 0,
            'progress': 0.0,
          };
          continue;
        }
        
        final usrDeptId = usrDeptData['id'];
        
        final questionsData = await Supabase.instance.client
            .from('questions')
            .select('id')
            .eq('dept_id', deptId)
            .order('created_at');
        
        final totalQuestions = questionsData.length;
        
        final progressData = await Supabase.instance.client
            .from('usr_progress')
            .select('question_id, status')
            .eq('usr_dept_id', usrDeptId)
            .order('created_at');
        
        int answeredCount = 0;
        int firstUnansweredIndex = 0;
        bool foundUnanswered = false;
        
        for (int i = 0; i < questionsData.length; i++) {
          final questionId = questionsData[i]['id'];
          
          final progress = progressData.firstWhere(
            (p) => p['question_id'] == questionId,
            orElse: () => {'status': 'pending'},
          );
          
          if (progress['status'] == 'answered') {
            answeredCount++;
          } else if (!foundUnanswered) {
            firstUnansweredIndex = i;
            foundUnanswered = true;
          }
        }
        
        if (!foundUnanswered && totalQuestions > 0) {
          firstUnansweredIndex = 0;
        }
        
        final progressPercentage = totalQuestions > 0 
            ? answeredCount / totalQuestions 
            : 0.0;
        
        _categoryProgress[category] = {
          'total': totalQuestions,
          'answered': answeredCount,
          'firstUnansweredIndex': firstUnansweredIndex,
          'progress': progressPercentage,
        };
        
        debugPrint('📊 $category Progress: $answeredCount/$totalQuestions (${(progressPercentage * 100).toStringAsFixed(0)}%), First unanswered: $firstUnansweredIndex');
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading category progress: $e');
    }
  }
