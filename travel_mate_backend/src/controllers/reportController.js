/**
 * 신고 컨트롤러
 * entityType: user|post|itinerary|comment, entityId, reportType, reason. 중복 신고 시 409.
 */
const Report = require('../models/report');
const User = require('../models/user');
const Post = require('../models/post');
const Itinerary = require('../models/itinerary');
const Comment = require('../models/comment');
const { LIMITS, checkMaxLength } = require('../utils/fieldLimits');

/** 신고 접수: entityType·entityId·reportType 필수 */
exports.submitReport = async (req, res, next) => {
  try {
    const { entityType, entityId, reportType, reason } = req.body;
    const reporterFirebaseUid = req.user.uid;

    if (!entityType || !entityId || !reportType) {
      return res.status(400).json({ message: '대상 타입, 대상 ID, 신고 유형이 필요합니다.' });
    }
    let err = checkMaxLength(reportType, LIMITS.reportType, '신고 유형');
    if (err) return res.status(400).json({ message: err });
    if (reason != null) {
      err = checkMaxLength(reason, LIMITS.reportReason, '신고 사유');
      if (err) return res.status(400).json({ message: err });
    }

    const reporter = await User.findOne({ where: { firebase_uid: reporterFirebaseUid } });
    if (!reporter) {
      return res.status(404).json({ message: '신고자를 찾을 수 없습니다.' });
    }

    let reportedUserId = null;
    let reportedPostId = null;
    let reportedItineraryId = null;
    let reportedCommentId = null;

    switch (entityType) {
      case 'user':
        const reportedUser = await User.findOne({ where: { email: entityId } });
        if (!reportedUser) return res.status(404).json({ message: '신고 대상 사용자를 찾을 수 없습니다.' });
        reportedUserId = reportedUser.email;
        break;
      case 'post':
        const reportedPost = await Post.findByPk(entityId);
        if (!reportedPost) return res.status(404).json({ message: 'Reported post not found' });
        reportedPostId = reportedPost.id;
        break;
      case 'itinerary':
        const reportedItinerary = await Itinerary.findByPk(entityId);
        if (!reportedItinerary) return res.status(404).json({ message: '신고 대상 일정을 찾을 수 없습니다.' });
        reportedItineraryId = reportedItinerary.id;
        break;
      case 'comment':
        const reportedComment = await Comment.findByPk(entityId);
        if (!reportedComment) return res.status(404).json({ message: '신고 대상 댓글을 찾을 수 없습니다.' });
        reportedCommentId = reportedComment.id;
        break;
      default:
        return res.status(400).json({ message: '잘못된 대상 타입입니다.' });
    }

    const reportedEntityId = entityType === 'user' ? reportedUserId : entityId;
    const existingReport = await Report.findOne({
      where: {
        reporterUserId: reporter.email,
        [entityType === 'user' ? 'reportedUserId' :
         entityType === 'post' ? 'reportedPostId' :
         entityType === 'itinerary' ? 'reportedItineraryId' :
         'reportedCommentId']: reportedEntityId,
      }
    });

    if (existingReport) {
      return res.status(409).json({ message: '이미 신고한 대상입니다.' });
    }

    const report = await Report.create({
      reporterUserId: reporter.email,
      reportedUserId,
      reportedPostId,
      reportedItineraryId,
      reportedCommentId,
      reportType,
      reason,
    });

    res.status(201).json({ message: '신고가 접수되었습니다.', report });
  } catch (error) {
    console.error('submitReport 오류:', error);
    next(error);
  }
};