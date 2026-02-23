/**
 * 댓글 컨트롤러
 * 게시글/일정 댓글 목록 조회, 댓글 작성, 댓글 삭제. 작성자에게 FCM 알림 전송.
 */
const Comment = require('../models/comment');
const User = require('../models/user');
const Post = require('../models/post');
const Itinerary = require('../models/itinerary');
const NotificationService = require('../services/notificationService');
const { LIMITS, checkMaxLength } = require('../utils/fieldLimits');

/** 댓글 목록: 쿼리 postId 또는 itineraryId, 최상위 댓글+대댓글 포함 */
exports.getComments = async (req, res, next) => {
  try {
    const { postId, itineraryId } = req.query;
    const whereConditions = { parentCommentId: null }; // Top-level comments

    if (postId) {
      whereConditions.postId = postId;
    } else if (itineraryId) {
      whereConditions.itineraryId = itineraryId;
    } else {
      return res.status(400).json({ message: 'postId 또는 itineraryId가 필요합니다.' });
    }

    const comments = await Comment.findAll({
      where: whereConditions,
      include: [
        { model: User, as: 'Author', attributes: ['firebase_uid', 'email'] },
        {
          model: Comment,
          as: 'Replies',
          include: [
            { model: User, as: 'Author', attributes: ['firebase_uid', 'email'] },
          ],
        },
      ],
      order: [['created_at', 'ASC']],
    });

    res.status(200).json({ comments });
  } catch (error) {
    console.error('getComments 오류:', error);
    next(error);
  }
};

exports.addComment = async (req, res, next) => {
  try {
    const { postId, itineraryId, parentCommentId, content } = req.body;
    const authorFirebaseUid = req.user.uid; // From authMiddleware

    if (!content) {
      return res.status(400).json({ message: '댓글 내용이 필요합니다.' });
    }
    const contentErr = checkMaxLength(content, LIMITS.commentContent, '댓글 내용');
    if (contentErr) return res.status(400).json({ message: contentErr });
    if (!postId && !itineraryId) {
      return res.status(400).json({ message: 'postId 또는 itineraryId가 필요합니다.' });
    }

    const author = await User.findOne({ where: { firebase_uid: authorFirebaseUid } });
    if (!author) {
      return res.status(404).json({ message: '작성자를 찾을 수 없습니다.' });
    }

    // Ensure content exists
    let parentContent = null;
    if (postId) {
      parentContent = await Post.findByPk(postId);
    } else if (itineraryId) {
      parentContent = await Itinerary.findByPk(itineraryId);
    }
    if (!parentContent) {
      return res.status(404).json({ message: '대상 게시글 또는 일정을 찾을 수 없습니다.' });
    }

    const comment = await Comment.create({
      authorId: author.email,
      postId: postId || null,
      itineraryId: itineraryId || null,
      parentCommentId: parentCommentId || null,
      content,
    });

    // Send FCM notification to content author or parent comment author
    let receiverFirebaseUid;
    let notificationTitle;
    let notificationBody;

    if (parentCommentId) { // It's a reply
      const parentComment = await Comment.findByPk(parentCommentId, {
        include: [{ model: User, as: 'Author' }],
      });
      if (parentComment && parentComment.Author.firebase_uid !== authorFirebaseUid) {
        receiverFirebaseUid = parentComment.Author.firebase_uid;
        notificationTitle = `New reply from ${author.email}`; // TODO: Use author nickname
        notificationBody = content;
      }
    } else if (parentContent.Author.firebase_uid !== authorFirebaseUid) { // New comment on a post/itinerary
      receiverFirebaseUid = parentContent.Author.firebase_uid;
      notificationTitle = `New comment on your ${postId ? 'post' : 'itinerary'} from ${author.email}`; // TODO: Use author nickname
      notificationBody = content;
    }

    if (receiverFirebaseUid) {
      await NotificationService.sendFCM(receiverFirebaseUid, {
        title: notificationTitle,
        body: notificationBody,
        data: {
          type: 'new_comment',
          commentId: comment.id.toString(),
          postId: postId ? postId.toString() : '',
          itineraryId: itineraryId ? itineraryId.toString() : '',
          senderId: authorFirebaseUid,
        },
      });
    }

    res.status(201).json({ message: '댓글이 등록되었습니다.', comment });
  } catch (error) {
    console.error('Error in addComment:', error);
    next(error);
  }
};

exports.updateComment = async (req, res, next) => {
  try {
    const { commentId } = req.params;
    const { content } = req.body;
    const authorFirebaseUid = req.user.uid; // From authMiddleware

    if (!content) {
      return res.status(400).json({ message: '댓글 내용이 필요합니다.' });
    }
    const contentErr = checkMaxLength(content, LIMITS.commentContent, '댓글 내용');
    if (contentErr) return res.status(400).json({ message: contentErr });

    const comment = await Comment.findByPk(commentId, {
      include: [{ model: User, as: 'Author' }],
    });

    if (!comment) {
      return res.status(404).json({ message: '댓글을 찾을 수 없습니다.' });
    }

    // Authorization: Only the author can update their comment
    if (comment.Author.firebase_uid !== authorFirebaseUid) {
      return res.status(403).json({ message: '본인 댓글만 수정할 수 있습니다.' });
    }

    await comment.update({ content });

    res.status(200).json({ message: '댓글이 수정되었습니다.', comment });
  } catch (error) {
    console.error('updateComment 오류:', error);
    next(error);
  }
};

exports.deleteComment = async (req, res, next) => {
  try {
    const { commentId } = req.params;
    const authorFirebaseUid = req.user.uid; // From authMiddleware

    const comment = await Comment.findByPk(commentId, {
      include: [{ model: User, as: 'Author' }],
    });

    if (!comment) {
      return res.status(404).json({ message: '댓글을 찾을 수 없습니다.' });
    }

    // Authorization: Only the author can delete their comment
    if (comment.Author.firebase_uid !== authorFirebaseUid) {
      return res.status(403).json({ message: '본인 댓글만 삭제할 수 있습니다.' });
    }

    await comment.destroy();

    res.status(204).send(); // No content for successful deletion
  } catch (error) {
    console.error('deleteComment 오류:', error);
    next(error);
  }
};
