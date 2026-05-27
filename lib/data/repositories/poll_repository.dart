import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/poll_model.dart';
import 'package:jugendkompass_app/data/models/poll_vote_model.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';

class PollRepository {
  final SupabaseClient _supabase;

  PollRepository(this._supabase);

  /// Get list of polls with optional filtering and calculate votes from poll_votes table
  Future<List<PollModel>> getPollList({
    int limit = 20,
    int offset = 0,
    bool activeOnly = true,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseConstants.pollsTable)
          .select('*');

      // Filter for active polls only (BEFORE ordering)
      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      // Apply ordering and pagination
      final pollsResponse = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Handle empty response
      if (pollsResponse == null || (pollsResponse is List && pollsResponse.isEmpty)) {
        return [];
      }

      final pollIds = (pollsResponse as List).map((p) => p['id'].toString()).toList();

      // Fetch all options for these polls, ordered by sort_order
      final allOptions = await _supabase
          .from(SupabaseConstants.pollOptionsTable)
          .select('*')
          .inFilter('poll_id', pollIds)
          .order('sort_order', ascending: true);

      // Group options by poll_id (use votes field from poll_options directly)
      final Map<String, List<Map<String, dynamic>>> optionsByPoll = {};
      for (final option in allOptions as List) {
        final pollId = option['poll_id'].toString();
        final opt = Map<String, dynamic>.from(option);
        // Use the votes field from poll_options table (updated by database trigger)

        if (!optionsByPoll.containsKey(pollId)) {
          optionsByPoll[pollId] = [];
        }
        optionsByPoll[pollId]!.add(opt);
      }

      // Build poll data with options
      final pollsData = (pollsResponse as List).map((pollJson) {
        final pollData = Map<String, dynamic>.from(pollJson);
        final pollId = pollData['id'].toString();
        pollData['poll_options'] = optionsByPoll[pollId] ?? [];
        return pollData;
      }).toList();

      final polls = pollsData
          .map((json) => PollModel.fromJson(json))
          .toList();

      // Filter out expired polls if activeOnly
      if (activeOnly) {
        return polls.where((poll) => poll.isActiveNow).toList();
      }

      return polls;
    } catch (e) {
      // Return empty list instead of throwing to prevent breaking the content feed
      debugPrint('Error loading polls: $e');
      return [];
    }
  }

  /// Get a single poll by ID with options and calculate votes from poll_votes table
  Future<PollModel?> getPollById(String id) async {
    try {
      // Fetch poll basic data
      final pollResponse = await _supabase
          .from(SupabaseConstants.pollsTable)
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (pollResponse == null) return null;

      // Fetch poll options separately, ordered by sort_order
      final optionsResponse = await _supabase
          .from(SupabaseConstants.pollOptionsTable)
          .select('*')
          .eq('poll_id', id)
          .order('sort_order', ascending: true);

      // Use votes field from poll_options directly (updated by database trigger)
      final options = (optionsResponse as List).map((opt) {
        return Map<String, dynamic>.from(opt);
      }).toList();

      // Combine poll data with options
      final pollData = Map<String, dynamic>.from(pollResponse);
      pollData['poll_options'] = options;

      return PollModel.fromJson(pollData);
    } catch (e) {
      debugPrint('Error loading poll by ID: $e');
      return null;
    }
  }

  /// Get user's vote for a specific poll
  Future<PollVoteModel?> getUserVote(String pollId, String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.pollVotesTable)
          .select()
          .eq('poll_id', pollId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return PollVoteModel.fromJson(response);
      }
      return null;
    } catch (e) {
      // User might not have voted yet, which is fine
      return null;
    }
  }

  /// Submit a vote for a poll option
  /// The database trigger automatically updates poll_options.votes on insert
  /// Re-voting is NOT allowed - throws exception if user already voted
  Future<void> submitVote(String pollId, String optionId, String userId) async {
    try {
      // Simple insert - database trigger will handle vote count increment
      await _supabase.from(SupabaseConstants.pollVotesTable).insert({
        'poll_id': pollId,
        'option_id': optionId,
        'user_id': userId,
      });
    } on PostgrestException catch (e) {
      // Check for unique constraint violation (code 23505)
      if (e.code == '23505') {
        throw Exception('Du hast bereits an dieser Umfrage teilgenommen');
      }
      throw Exception('Fehler beim Abstimmen: ${e.message}');
    } catch (e) {
      throw Exception('Fehler beim Abstimmen: $e');
    }
  }

  /// Get localized polls using Supabase RPC function
  Future<List<PollModel>> getPollsLocalized(
    String language, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_polls_localized',
        params: {'lang': language},
      );

      final polls = (response as List)
          .map((json) => PollModel.fromJson(json))
          .toList();

      // Apply limit and offset client-side
      return polls.skip(offset).take(limit).toList();
    } catch (e) {
      // Fallback to regular polls if RPC fails
      return getPollList(limit: limit, offset: offset);
    }
  }
}
