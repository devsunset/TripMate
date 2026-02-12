/**
 * 좋아요·북마크 컨트롤러
 * 게시글/일정에 대한 좋아요·북마크 토글. contentId, contentType(body) 사용.
 */
const Like = require('../models/like');
const Bookmark = require('../models/bookmark');
const User = require('../models/user');
const Post = require('../models/post');
const Itinerary = require('../models/itinerary');
const { Op } = require('sequelize');

/** 좋아요/북마크 토글 공통: 있으면 삭제, 없으면 생성. countChange는 좋아요용 */
async function toggleInteraction(model, userId, contentId, contentType) {
  const user = await User.findOne({ where: { firebase_uid: userId } });
  if (!user) throw new Error('사용자를 찾을 수 없습니다.');

  const interactionWhere = { userId: user.id, postId: null, itineraryId: null };
  if (contentType === 'post') {
    interactionWhere.postId = contentId;
    const post = await Post.findByPk(contentId);
    if (!post) throw new Error('게시글을 찾을 수 없습니다.');
  } else if (contentType === 'itinerary') {
    interactionWhere.itineraryId = contentId;
    const itinerary = await Itinerary.findByPk(contentId);
    if (!itinerary) throw new Error('일정을 찾을 수 없습니다.');
  } else {
    throw new Error('잘못된 콘텐츠 타입입니다.');
  }

  const existingInteraction = await model.findOne({ where: interactionWhere });

  if (existingInteraction) {
    await existingInteraction.destroy();
    return { created: false, countChange: -1 };
  } else {
    await model.create(interactionWhere);
    return { created: true, countChange: 1 };
  }
}

exports.toggleLike = async (req, res, next) => {
  try {
    const { contentId, contentType } = req.body;
    const userId = req.user.uid; // From authMiddleware

    const { created, countChange } = await toggleInteraction(Like, userId, contentId, contentType);

    res.status(200).json({
      message: created ? '좋아요를 눌렀습니다.' : '좋아요를 취소했습니다.',
      isLiked: created,
      likeCountChange: countChange,
    });
  } catch (error) {
    console.error('toggleLike 오류:', error);
    if (['사용자를 찾을 수 없습니다.', '게시글을 찾을 수 없습니다.', '일정을 찾을 수 없습니다.', '잘못된 콘텐츠 타입입니다.'].includes(error.message)) {
      return res.status(404).json({ message: error.message });
    }
    next(error);
  }
};

exports.toggleBookmark = async (req, res, next) => {
  try {
    const { contentId, contentType } = req.body;
    const userId = req.user.uid; // From authMiddleware

    const { created } = await toggleInteraction(Bookmark, userId, contentId, contentType);

    res.status(200).json({
      message: created ? 'Bookmarked successfully' : 'Unbookmarked successfully',
      isBookmarked: created,
    });
  } catch (error) {
    console.error('toggleBookmark 오류:', error);
    if (['사용자를 찾을 수 없습니다.', '게시글을 찾을 수 없습니다.', '일정을 찾을 수 없습니다.', '잘못된 콘텐츠 타입입니다.'].includes(error.message)) {
      return res.status(404).json({ message: error.message });
    }
    next(error);
  }
};
