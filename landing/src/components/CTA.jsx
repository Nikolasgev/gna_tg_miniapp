import React, { useState } from 'react'
import { motion } from 'framer-motion'
import { ArrowRight, CheckCircle2, Mail, Phone } from 'lucide-react'

const CTA = ({ onOpenModal }) => {
  const [email, setEmail] = useState('')
  const [submitted, setSubmitted] = useState(false)

  const handleSubmit = (e) => {
    e.preventDefault()
    // Здесь будет логика отправки формы
    setSubmitted(true)
    setTimeout(() => {
      setSubmitted(false)
      setEmail('')
    }, 3000)
  }

  return (
    <section id="cta" className="py-20 bg-gradient-to-br from-slate-800 via-slate-700 to-slate-900 text-white relative overflow-hidden">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 left-0 w-96 h-96 bg-white rounded-full filter blur-3xl"></div>
        <div className="absolute bottom-0 right-0 w-96 h-96 bg-white rounded-full filter blur-3xl"></div>
      </div>

      <div className="relative max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center"
        >
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            Готовы начать продавать в Telegram?
          </h2>
          <p className="text-xl text-slate-200 mb-12 max-w-2xl mx-auto">
            Присоединяйтесь к сотням успешных магазинов. Начните бесплатно уже сегодня.
          </p>

          {/* Form */}
          <motion.form
            onSubmit={handleSubmit}
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="max-w-md mx-auto mb-8"
          >
            <div className="flex flex-col sm:flex-row gap-4">
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Ваш email"
                required
                className="flex-1 px-6 py-4 rounded-full text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-white"
              />
              <motion.button
                type="button"
                onClick={onOpenModal}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="bg-white text-slate-800 px-8 py-4 rounded-full font-semibold hover:shadow-xl transition-all flex items-center justify-center gap-2 whitespace-nowrap"
              >
                Начать бесплатно
                <ArrowRight className="w-5 h-5" />
              </motion.button>
            </div>
          </motion.form>

          {/* Benefits */}
          <div className="grid md:grid-cols-3 gap-6 mt-12">
            {[
              'Без кредитной карты',
              '14 дней бесплатно',
              'Отмена в любой момент',
            ].map((benefit, index) => (
              <motion.div
                key={benefit}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6, delay: 0.3 + index * 0.1 }}
                className="flex items-center justify-center gap-2 text-slate-200"
              >
                <CheckCircle2 className="w-5 h-5" />
                <span>{benefit}</span>
              </motion.div>
            ))}
          </div>

          {/* Contact Info */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.6 }}
            className="mt-12 pt-8 border-t border-white/20 flex flex-col sm:flex-row items-center justify-center gap-6 text-slate-200"
          >
            <a
              href="mailto:hello@telegramstore.ru"
              className="flex items-center gap-2 hover:text-white transition-colors"
            >
              <Mail className="w-5 h-5" />
              hello@telegramstore.ru
            </a>
            <a
              href="tel:+79991234567"
              className="flex items-center gap-2 hover:text-white transition-colors"
            >
              <Phone className="w-5 h-5" />
              +7 (999) 123-45-67
            </a>
          </motion.div>
        </motion.div>
      </div>
    </section>
  )
}

export default CTA

