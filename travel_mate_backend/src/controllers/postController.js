/**
 * 게시글 컨트롤러
 * 목록 조회(카테고리·검색), 단건 조회, 생성, 수정, 삭제. 작성자만 수정/삭제 가능.
 */
const { Op } = require('sequelize');
const Post = require('../models/post');
const PostCategory = require('../models/postCategory');
const User = require('../models/user');
const { LIMITS, checkMaxLength } = require('../utils/fieldLimits');

/** 게시글 목록: 쿼리 category, search, limit, offset */
exports.getAllPosts = async (req, res, next) => {
  try {
    const { category, search, limit = 10, offset = 0 } = req.query;
    const whereConditions = {};

    if (category) {
      const postCategory = await PostCategory.findOne({ where: { name: category } });
      if (postCategory) {
        whereConditions.categoryId = postCategory.id;
      } else {
        return res.status(404).json({ message: '카테고리를 찾을 수 없습니다.' });
      }
    }

    if (search) {
      whereConditions[Op.or] = [
        { title: { [Op.like]: `%${search}%` } },
        { content: { [Op.like]: `%${search}%` } },
      ];
    }

    const posts = await Post.findAndCountAll({
      where: whereConditions,
      include: [
        { model: User, as: 'Author', attributes: ['firebase_uid', 'email'] }, // Include author info
        { model: PostCategory, as: 'Category', attributes: ['name'] }, // Include category name
      ],
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['created_at', 'DESC']],
    });

    res.status(200).json({
      total: posts.count,
      limit: parseInt(limit),
      offset: parseInt(offset),
      posts: posts.rows,
    });
  } catch (error) {
    console.error('getAllPosts 오류:', error);
    next(error);
  }
};

exports.getPostById = async (req, res, next) => {
  try {
    const { postId } = req.params;

    const post = await Post.findByPk(postId, {
      include: [
        { model: User, as: 'Author', attributes: ['firebase_uid', 'email'] },
        { model: PostCategory, as: 'Category', attributes: ['name'] },
      ],
    });

    if (!post) {
      return res.status(404).json({ message: '게시글을 찾을 수 없습니다.' });
    }

    res.status(200).json({ post });
  } catch (error) {
    console.error('getPostById 오류:', error);
    next(error);
  }
};

exports.createPost = async (req, res, next) => {
  try {
    const { title, content, category, imageUrls } = req.body;
    const authorFirebaseUid = req.user.uid; // From authMiddleware

    if (!title || !content || !category) {
      return res.status(400).json({ message: '제목, 내용, 카테고리가 필요합니다.' });
    }
    let err = checkMaxLength(title, LIMITS.postTitle, '제목');
    if (err) return res.status(400).json({ message: err });
    err = checkMaxLength(content, LIMITS.postContent, '본문');
    if (err) return res.status(400).json({ message: err });

    const author = await User.findOne({ where: { firebase_uid: authorFirebaseUid } });
    if (!author) {
      return res.status(404).json({ message: '작성자를 찾을 수 없습니다.' });
    }

    const postCategory = await PostCategory.findOne({ where: { name: category } });
    if (!postCategory) {
      return res.status(404).json({ message: '카테고리를 찾을 수 없습니다.' });
    }

    const post = await Post.create({
      authorId: author.email,
      categoryId: postCategory.id,
      title,
      content,
      imageUrls: imageUrls || [],
    });

    res.status(201).json({ message: '게시글이 작성되었습니다.', post });
  } catch (error) {
    console.error('createPost 오류:', error);
    next(error);
  }
};

exports.updatePost = async (req, res, next) => {
  try {
    const { postId } = req.params;
    const { title, content, category, imageUrls } = req.body;
    const authorFirebaseUid = req.user.uid; // From authMiddleware

    const post = await Post.findByPk(postId, {
      include: [{ model: User, as: 'Author' }],
    });

    if (!post) {
      return res.status(404).json({ message: '게시글을 찾을 수 없습니다.' });
    }

    // Authorization: Only the author can update their post
    if (post.Author.firebase_uid !== authorFirebaseUid) {
      return res.status(403).json({ message: '본인 게시글만 수정할 수 있습니다.' });
    }
    if (title != null) {
      const err = checkMaxLength(title, LIMITS.postTitle, '제목');
      if (err) return res.status(400).json({ message: err });
    }
    if (content != null) {
      const err = checkMaxLength(content, LIMITS.postContent, '본문');
      if (err) return res.status(400).json({ message: err });
    }

    let categoryId = post.categoryId;
    if (category) {
      const postCategory = await PostCategory.findOne({ where: { name: category } });
      if (!postCategory) {
        return res.status(404).json({ message: '카테고리를 찾을 수 없습니다.' });
      }
      categoryId = postCategory.id;
    }

    await post.update({
      title: title || post.title,
      content: content || post.content,
      categoryId: categoryId,
      imageUrls: imageUrls || post.imageUrls,
    });

    res.status(200).json({ message: '게시글이 수정되었습니다.', post });
  } catch (error) {
    console.error('updatePost 오류:', error);
    next(error);
  }
};

exports.deletePost = async (req, res, next) => {
  try {
    const { postId } = req.params;
    const authorFirebaseUid = req.user.uid; // From authMiddleware

    const post = await Post.findByPk(postId, {
      include: [{ model: User, as: 'Author' }],
    });

    if (!post) {
      return res.status(404).json({ message: '게시글을 찾을 수 없습니다.' });
    }

    // Authorization: Only the author can delete their post
    if (post.Author.firebase_uid !== authorFirebaseUid) {
      return res.status(403).json({ message: '본인 게시글만 삭제할 수 있습니다.' });
    }

    await post.destroy();

    res.status(204).send(); // No content for successful deletion
  } catch (error) {
    console.error('deletePost 오류:', error);
    next(error);
  }
};
